import { connect, close, parseConnectionString, addDebugHander, tabulate } from "./sql-adapter";
import { Connection, Request, type ConnectionConfiguration, TYPES as SQL_TYPES } from "tedious";

import { readFileSync, writeFileSync } from "node:fs";

const connectionConfig: ConnectionConfiguration = parseConnectionString(process.env.DB_GEMSTONE_CONNECTION_STRING);
connectionConfig.options!.rowCollectionOnRequestCompletion = true;

// Logging the configuration helps debug issues like wrong server names.
// Notice the server name here and compare it with what works in `telnet`.
console.log("Attempting to connect with config:", {
	server: connectionConfig.server,
	database: connectionConfig.options?.database,
	userName: connectionConfig.authentication?.options.userName,
});

const gemstoneConnection = new Connection(connectionConfig);
// addDebugHander(gemstoneConnection);

export async function publicNoticesExtract(): Promise<string> {

	try {
		await connect(gemstoneConnection);

		const scriptPath = "dist/sql/gemstone-pnp-select.sql";
		const sql = readFileSync(scriptPath, "utf-8").replace(/(.*?\n)*-- start.*\n*/, "");

		// Promisify the tedious request to make it await-able
		const rows = await new Promise<any[]>((resolve, reject) => {
			const request = new Request(
				sql,
				(err, rowCount, rows) => {
					if (err) {
						console.error("SQL Error:", err);
						return reject(err);
					}
					console.log(`${rowCount} row(s) returned`);
					// The promise resolves with the rows from the database
					resolve(rows);
				}
			);

			const publication_data_param = new Date().toISOString().slice(0, 10);
			console.log(`Using publication date parameter: ${publication_data_param}`);
			request.addParameter("publication_date", SQL_TYPES.Date, publication_data_param);

			gemstoneConnection.execSql(request);
		});
		return JSON.stringify(rows, null, 2);

	} catch (err: any) {
		console.error("An error occurred during publicNoticesExtract:", err);
		throw err; // Re-throw the error so the caller can handle it.
	} finally {
		// This block ensures the connection is closed, whether the try block succeeded or failed.
		if (gemstoneConnection.state.name !== 'Final') {
			close(gemstoneConnection);
		}
	}
}