// Google Apps Script for sending AWS workshop credentials
// Paste this into Extensions → Apps Script in a new Google Sheet

const CREDENTIALS_CSV = `
username,password,access_key_id,secret_access_key
workshop-user-01,Workshop1a2b3c4d!,AKIAXXXXXXXX,secretkey1
workshop-user-02,Workshop5e6f7g8h!,AKIAYYYYYYYY,secretkey2
`.trim();

const ATTENDEES_CSV = `
"First Name","Last Name","Email","Account Type","Is Member","Membership End Date","Degree","Member Tags","User Tags","RSVP'ed","Registration Option","Quantity","Registration Status","Registration Date","Attendee's Comment","Officer's Notes","Member's Notes","Payment Date","On the Wait List","Promoted to Main List","Checked-In Date","Checked-Out Date","No Show Date","RSVP'ed at the door","Attendee's Rating","Attendee's Feedback","Net ID","Event Registration UID","CG Payment UID","CG Payment ID","Alumni ID"
"Ben","Juntilla","benjuntilla@asu.edu","Student","Yes","","","","","Yes","RSVP","1","COMPLETE","1/24/2026 12:00:00 AM","","","","","No","No","1/27/2026 7:00:00 PM","","","No","","","bjuntill","","","",""
"Test","User","asu@thesoda.io","Student","Yes","","","","","Yes","RSVP","1","COMPLETE","1/24/2026 12:00:00 AM","","","","","No","No","1/27/2026 7:00:00 PM","","","No","","","testuser","","","",""
`.trim();

function parseCsv(csv) {
  const lines = csv.split('\n');
  return lines.map(line => {
    const result = [];
    let current = '';
    let inQuotes = false;
    for (const char of line) {
      if (char === '"') {
        inQuotes = !inQuotes;
      } else if (char === ',' && !inQuotes) {
        result.push(current);
        current = '';
      } else {
        current += char;
      }
    }
    result.push(current);
    return result;
  });
}

function sendCredentials() {
  const creds = parseCsv(CREDENTIALS_CSV);
  const attendees = parseCsv(ATTENDEES_CSV);

  // Validate credentials columns
  const credsHeader = creds[0];
  const expectedCredsHeader = ['username', 'password', 'access_key_id', 'secret_access_key'];
  expectedCredsHeader.forEach((col, i) => {
    if (credsHeader[i] !== col) {
      throw new Error(`credentials column ${i} should be '${col}', got '${credsHeader[i]}'`);
    }
  });

  // Validate attendees columns
  const attendeesHeader = attendees[0];
  if (attendeesHeader[0] !== 'First Name') {
    throw new Error(`attendees column 0 should be 'First Name', got '${attendeesHeader[0]}'`);
  }
  if (attendeesHeader[2] !== 'Email') {
    throw new Error(`attendees column 2 should be 'Email', got '${attendeesHeader[2]}'`);
  }

  console.log(`Validated: ${creds.length - 1} credentials, ${attendees.length - 1} attendees`);

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
