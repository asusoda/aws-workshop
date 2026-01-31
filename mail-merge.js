// Google Apps Script for sending AWS workshop credentials
// Paste this into Extensions → Apps Script in your Google Sheet

function sendCredentials() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  const credsSheet = ss.getSheetByName('credentials');
  const attendeesSheet = ss.getSheetByName('attendees');

  if (!credsSheet) throw new Error("Missing 'credentials' sheet");
  if (!attendeesSheet) throw new Error("Missing 'attendees' sheet");

  const creds = credsSheet.getDataRange().getValues();
  const attendees = attendeesSheet.getDataRange().getValues();

  // Validate credentials sheet columns
  const credsHeader = creds[0];
  const expectedCredsHeader = ['username', 'password', 'access_key_id', 'secret_access_key'];
  expectedCredsHeader.forEach((col, i) => {
    if (credsHeader[i] !== col) {
      throw new Error(`credentials column ${i} should be '${col}', got '${credsHeader[i]}'`);
    }
  });

  // Validate attendees sheet columns
  const attendeesHeader = attendees[0];
  if (attendeesHeader[0] !== 'First Name') {
    throw new Error(`attendees column 0 should be 'First Name', got '${attendeesHeader[0]}'`);
  }
  if (attendeesHeader[2] !== 'Email') {
    throw new Error(`attendees column 2 should be 'Email', got '${attendeesHeader[2]}'`);
  }
  console.log(`Validated sheets: ${creds.length - 1} credentials, ${attendees.length - 1} attendees`);

  const subject = "Your AWS Workshop Credentials";
  const consoleUrl = "https://496851883920.signin.aws.amazon.com/console";

  let credIndex = 1; // skip header

  for (let i = 1; i < attendees.length; i++) {
    const firstName = attendees[i][0];
    const email = attendees[i][2];

    if (!email) continue;
    if (credIndex >= creds.length) {
      console.log("Ran out of credentials!");
      break;
    }

    const [username, password, accessKey, secretKey] = creds[credIndex];

    const body = `Hi ${firstName}!

Here are your AWS workshop credentials:

Console login: ${consoleUrl}
Username: ${username}
Password: ${password}

CLI credentials (optional):
Access Key ID: ${accessKey}
Secret Access Key: ${secretKey}

See you at the workshop!`;

    GmailApp.sendEmail(email, subject, body);
    console.log(`Sent ${username} to ${email}`);
    credIndex++;
  }

  console.log(`Done. Sent ${credIndex - 1} emails.`);
}
