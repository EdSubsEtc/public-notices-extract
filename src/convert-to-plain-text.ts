import { readFileSync, writeFileSync } from "node:fs";

import { rtfToText } from "./RTFToText.js";

const inputFilePath = "sql/gemstone-pnp-select-dev-by-id.sql".replace(/\.sql$/, ".output.json");
const outputFilePath = "sql/gemstone-pnp-select-dev-by-id.sql".replace(/\.sql$/, ".text.output.json");


const rows = JSON.parse(readFileSync(inputFilePath, "utf-8"));

const full : any[] = [];

rows.forEach((row: any) => {

	const urnCol = row.find((v: any) => {
		return v.metadata.colName == "urn_number";
	});
	const urn = urnCol.value;

	const rtf = row.find((v: any) => {
		return v.metadata.colName == "rtf";
	});

	const title = row.find((v: any) => {
		return v.metadata.colName == "title_long_name";
	});

	const classification = row.find((v: any) => {
		return v.metadata.colName == "classification";
	});


	let text = ""

	if (rtf.value) {
		text = rtfToText(rtf.value);
		writeFileSync("text/" + urn + ".txt", text, "utf-8");
	}

	full.push({
		urn: urn,
		title: title.value,
		classification: classification.value,
		text: text
	});

})

writeFileSync( outputFilePath, JSON.stringify( full , null , 2 ) , "utf-8")

