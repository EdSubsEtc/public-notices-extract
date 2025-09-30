import { rtfToText } from "./RTFToText.js";
import { readFileSync, writeFileSync } from "node:fs";
import { connect, close, parseConnectionString, addDebugHander, tabulate } from "./sql-adapter.js";
import { Connection, Request, type ConnectionConfiguration, TYPES as SQL_TYPES } from "tedious";

const year = 2025;
const month = 8 -1; // js dates are 0 based!

const startDate = new Date(year, month, 1);
let date = startDate;
const endDate = new Date(year, month + 1, 1);

interface PnPData {
	urnNumber: string,
	publicationDate: string,
	title: string[],
	classification: string,
	style: string,
	outputPDFAvaliability: string,
	notice: {
		title: string,
		firstParagraph: string,
		body: string;
		rtf?: string;
	};
};

async function main() {
	const connectionConfig: ConnectionConfiguration = parseConnectionString(process.env.DB_GEMSTONE_CONNECTION_STRING);
	connectionConfig.options!.rowCollectionOnRequestCompletion = true;

	const gemstoneConnection = new Connection(connectionConfig);
	addDebugHander(gemstoneConnection);

	await connect(gemstoneConnection);

	const sql = readFileSync("sql/gemstone-pnp-select-live.sql", "utf-8")
		.replace(/(.*?\n)*-- start.*\n*/, "");

	while (date < endDate) {
		console.log(`Get Public Notices for ${date.toISOString().slice(0, 10)}`);

		await new Promise<void>((resolve, reject) => {
			const request = new Request(
				sql,
				(err, rowCount, rows) => {
					if (err) {
						console.error("SQL Error:", err);
						return reject(err);
					}

					console.log(`${rowCount} row(s) returned`);

					const data: Map<string, PnPData> = new Map();
					let orderCount = 0;

					rows.forEach((row: any) => {
						const mapped = new Map<string, any>();
						row.map((v: any) => mapped.set(v.metadata.colName, v.value));

						const urnNumber = mapped.get("urnNumber");

						let plainText = mapped.get("rtf");
						if (plainText) {
							plainText = rtfToText(plainText);
						}

						if (data.has(urnNumber)) {
							data.get(urnNumber)?.title.push(mapped.get("title"));
						} else {
							orderCount++;
							data.set(urnNumber, {
								urnNumber: urnNumber,
								publicationDate: mapped.get("publicationDate").toISOString().slice(0, 10),
								title: [mapped.get("title")],
								classification: mapped.get("classification"),
								style: mapped.get("style"),
								outputPDFAvaliability: mapped.get("outputPFAvaliability"),
								notice: {
									title: mapped.get("noticeTitle"),
									firstParagraph: mapped.get("noticeFirstParagraph"),
									body: mapped.get("noticeBodyCopy"),
									rtf: plainText
								},
							});
						}
					});

					if (data.size > 0) {
						const outputFilePath = `data/public-notices-${date.toISOString().slice(0, 10)}.json`;
						writeFileSync(outputFilePath, JSON.stringify([...data.values()], null, 2), "utf-8");
						console.log(`${rows.length} notices over ${orderCount} orders.\nWritten to ${outputFilePath}`);
					}

					resolve();
				}
			);

			request.addParameter("publication_date", SQL_TYPES.Date, date);
			gemstoneConnection.execSql(request);
		});

		// next day
		date.setDate(date.getDate() + 1);
	}
	await close(gemstoneConnection);
}

main().catch(console.error);
