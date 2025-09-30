import { readFileSync, writeFileSync } from "node:fs";
import { rtfToText } from "./RTFToText.js";






const inputFilePath = "sql/gemstone-pnp-select-live.sql".replace(/\.sql$/, ".output.json");
const outputFilePath = inputFilePath.replace(/\.output\.json$/, ".pnp.json");

const rows = JSON.parse(readFileSync(inputFilePath, "utf-8"));

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

	if (data.get(urnNumber)) {
		data.get(urnNumber)?.title.push(mapped.get("title"));
		return;
	} else {

		orderCount++;

		data.set(urnNumber, {
			urnNumber: urnNumber,
			publicationDate: mapped.get("publicationDate").slice(0,10),
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

writeFileSync(outputFilePath, JSON.stringify([...data.values()], null, 2), "utf-8");

console.log(`${rows.length} notices over ${orderCount} orders.\nWritten to ${outputFilePath}`);