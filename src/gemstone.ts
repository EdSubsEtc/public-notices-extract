import { rtfToText } from "./RTFToText.js";
import { readFileSync, writeFileSync } from "node:fs";
import { connect, close, parseConnectionString, addDebugHander, tabulate } from "./sql-adapter.js";
import { Connection, Request, type ConnectionConfiguration, TYPES as SQL_TYPES } from "tedious";

export interface PnPData {
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

export async function getPublicNoticesByDate(date: Date): Promise<PnPData[]> {

	const connectionConfig: ConnectionConfiguration = parseConnectionString(process.env.DB_GEMSTONE_CONNECTION_STRING);
	connectionConfig.options!.rowCollectionOnRequestCompletion = true;

	const gemstoneConnection = new Connection(connectionConfig);
	addDebugHander(gemstoneConnection);

	await connect(gemstoneConnection);

	const sql = readFileSync( `${__dirname}/sql/gemstone-pnp-select.sql`, "utf-8")
		.replace(/(.*?\n)*-- start.*\n*/, "");

	console.log(`Get Public Notices for ${date.toISOString().slice(0, 10)}`);

	return new Promise<PnPData[]>((resolve, reject) => {

		const request = new Request(

			sql,
			(err, rowCount, rows) => {
				if (err) {
					console.error("SQL Error:", err);
					reject(err);
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
				close(gemstoneConnection);
				resolve([...data.values()]);
			}
		);
		request.addParameter("publication_date", SQL_TYPES.Date, date);
		gemstoneConnection.execSql(request);
	});

}
