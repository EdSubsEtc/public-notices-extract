import { Connection, type ConnectionConfiguration, Request, TYPES } from "tedious";
import { lookup as dnsLookup } from "node:dns";


export function parseConnectionString(connectionString: string | undefined): ConnectionConfiguration {

	if (!connectionString) {
		throw new Error("Database connection string is not defined. Please check your environment variables.");
	}

	const parts = connectionString.split(";");
	const partsMap = new Map();

	for (const part of parts) {
		const [key, value] = part.split("=");
		if (key)
			partsMap.set(key.toLowerCase(), value);
	}

	const config: ConnectionConfiguration = {
		server: partsMap.get("server"),
		authentication: {
			type: "default",
			options: {
				userName: partsMap.get("user"),
				password: partsMap.get("password"),
			}
		},
		options: {
			encrypt: true,
			database: partsMap.get("database"),
			trustServerCertificate: partsMap.get("trustservercertificate").toLowerCase() === "true"
			// , debug: {
			// 	packet: true,
			// 	data: true,
			// 	payload: true
			// }
		}
	};

	return config;
}

export function addDebugHander(connection: Connection) {
	connection.on("debug", (msg) => {
		console.debug(msg);
	});
}


export function connect(connection: Connection): Promise<void> {



	return new Promise((resolve, reject) => {

		// add a dns check and nudge the dumb developer to enable VPN if
		// no response



		// this is called once the connection connects or errors
		connection.connect((err) => {
			if (err) {
				console.error("Error connecting to the database:", err);
				return reject(err);
			}
			resolve();
		});
	});
}


export function close(connection: Connection): Promise<void> {
	return new Promise((resolve) => {
		// The 'end' event is the signal that the connection has successfully closed.
		// We use 'once' to ensure this listener is called only a single time and then removed,
		// preventing memory leaks if close() were to be called multiple times.
		connection.once('end', resolve);
		connection.close();
	});
}


export function tabulate(rows: any, err: any, options?: any) {

	const nVarCharLimit = options.nVarCharLimit || 100;
	const datetimeFormat = options.datetimeFormat || "iso";
	const showTypes = options.showTypes || true;

	let html = "";

	html += "<style>";
	html += "table { border-collapse: collapse; background-color: white; } ";
	html += "th, td { border: 1px solid black; padding: 5px; white-space: nowrap; }";
	html += ".sql-error { color: red; }";
	html += "</style>";
	html += "<table>";
	html += "<thead>";

	if (err) {
		html += "<tr><td>Error: " + err.message + "</td></tr>";

		err.errors?.forEach( (v:any) => {
			html += "<tr><td class=\"sql-error\">" + v.message + "</td></tr>";
		}) 

		
	}



	if (rows.length > 0) {
		html += "<tr>";
		rows[0].forEach((v: any) => html += `<th>${v.metadata.colName}</th>`);
		html += "</tr>";
	}

	if (rows.length > 0 && showTypes) {
		html += "<tr>";
		rows[0].forEach((v: any) => html += `<th>${v.metadata.type.name}</th>`);
		html += "</tr>";
	}

	if (rows.length === 0) {
		html += "<tr><td>No rows returned</td></tr>";
	}

	html += "</thead>";
	html += "<tbody>";

	rows.forEach((v: any) => {

		html += "<tr>";

		v.forEach((v: any) => {

			let display = "";

			if (v.value) {

				switch (v.metadata.type.name) {
					case "DateTimeN":
						display = v.value?.toISOString();
						display = display.replaceAll("T00:00:00.000Z", "");
						break;
					case "DateTime":
						display = v.value.toISOString();
						break;
					case "Date":
						display = v.value.toISOString().split("T")[0];
						break;
					case "NVarChar":
						if (v.value?.length > nVarCharLimit) {
							display = v.value.slice(0, nVarCharLimit) + "...";
						} else {
							display = v.value;
						}
						break;
					default:
						display = v.value;
				}
			} else {
				display = "NULL";
			}


			html += `<td>${display}</td>`;

		});

		html += "</tr>";
	});

	html += "</tbody>";
	html += "</table>";

	return html;

};






