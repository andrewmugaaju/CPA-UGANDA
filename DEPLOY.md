# Putting CPA Uganda on DigitalOcean

This moves the system from the office PC to DigitalOcean (App Platform for the app, a managed MySQL database for the data).
Read the four warnings first. The steps for Railway are at the end.

## Four warnings

1. **A card is needed.** DigitalOcean's new-customer trial gives a credit (about $200 for 60 days when this was written, check the offer on your account).
   When the 60 days end, whatever is still running is charged to the card. Write down the end date and decide before it.
2. **Member data leaves the office.** Names, phone numbers and balances will be on servers abroad (the nearest regions are Europe, such as Frankfurt or London).
   Make sure CPA agrees, and keep a backup copy at the office (step 9).
3. **Never put passwords or database dumps in GitHub.** `.gitignore` already keeps `backups`, `DOCS`, `.sql` and `.xlsx` files out.
   Type passwords only into DigitalOcean's pages, never into a file.
4. **Do not make a second trial account** with another email to get more free credit. It is against their rules and can close the account.

## Steps

### 1. Back up the office database
In PowerShell, in the project folder:

```powershell
C:\xampp\mysql\bin\mysqldump.exe -uroot --single-transaction cpa_uganda > backups\cpa_uganda_for_digitalocean.sql
```

### 2. Sign in and add the card
Open cloud.digitalocean.com, sign in, add the payment method, and check that the trial credit shows under **Billing**.

### 3. Create the database
1. **Create → Databases → MySQL** (version 8).
2. Region: **Frankfurt (FRA1)** or London. Use the same region for the app in step 6.
3. Choose the smallest plan (the one-node plan). Name it `cpa-db`. Create it. It takes a few minutes.
4. Open it → **Settings → Trusted Sources → Edit** and add **your own computer** ("Add current IP"). You need this for step 4.

### 4. Move the data into it
1. Open `cpa-db` → **Overview → Connection details → Public network**. Note the host, the port (usually 25060), the user (`doadmin`), the database (`defaultdb`) and the password.
2. In PowerShell (it asks for the password, so it is not written anywhere):

```powershell
C:\xampp\mysql\bin\mysql.exe -h HOST -P PORT -u doadmin -p --ssl defaultdb < backups\cpa_uganda_for_digitalocean.sql
```

The office database is MariaDB and DigitalOcean's is MySQL. This usually imports without trouble. If it prints an error, send me the message.
If it says the connection was refused, step 3.4 (your computer as a trusted source) is the cause.

### 5. Check that the data arrived
In the same window: `C:\xampp\mysql\bin\mysql.exe -h HOST -P PORT -u doadmin -p --ssl defaultdb -e "select count(*) from members"`
It should show 1021 members.

### 6. Create the app
1. **Create → Apps → GitHub.** Allow DigitalOcean to see your repositories and choose `andrewmugaaju/CPA-UGANDA`, branch `main`. Keep "Autodeploy" on.
2. It finds the `Dockerfile`. The component should be a **Web Service**.
3. **HTTP port: 8082.** Region: the same as the database.
4. **Size:** at least **1 GB of memory**. This Java app does not run well on less.
5. Do not press Create yet.

### 7. Tell the app where its database is
In the component's **Environment Variables** add these. Use the values from step 4 and tick **Encrypt** on the password:

| Name | Value |
|---|---|
| `DB_URL` | `jdbc:mysql://HOST:PORT/defaultdb?sslMode=REQUIRED&allowPublicKeyRetrieval=true&serverTimezone=UTC` |
| `DB_USER` | `doadmin` |
| `DB_PASSWORD` | the database password |

Then **Add Resource → Database → existing `cpa-db`**, so the app is allowed to reach it. Press **Create Resources**.
Because you restored the office database, the logins (`admin`, `support`) came with it. If you start from an empty database instead,
also add `CPA_ADMIN_PASSWORD` and `MANAGER_PASSWORD` with passwords of your own choice.

### 8. Start it and open it
1. Watch **Runtime Logs** until it says `Started SaccoApplication`. The first start takes a few minutes.
2. Open the app's address (it looks like `https://xxxx.ondigitalocean.app`) and sign in as `admin`.
3. Check Members, Loans, Savings interest, and that the Trial balance says **Balanced**.
4. Change the `admin` and `support` passwords with "Change password". Do not share the address publicly: it is the live system.

### 9. Backups
- DigitalOcean keeps daily backups of the database for 7 days.
- **Also keep your own, every week**, at the office:

```powershell
C:\xampp\mysql\bin\mysqldump.exe -h HOST -P PORT -u doadmin -p --ssl --single-transaction defaultdb > backups\digitalocean_backup.sql
```

(Your computer must be a trusted source, as in step 3.4.)

### 10. Before the trial ends
Look at **Billing → Usage** about a week before. Keep it running (the card is charged monthly) or download a backup and delete the app and the database.

## If something goes wrong
- **The app restarts again and again, or the log says "killed":** it ran out of memory. Make the component bigger (2 GB).
- **"Communications link failure" or "Access denied" in the log:** the app is not a trusted source of the database (step 7), or the host, port or password is wrong.
- **The page opens but login fails:** the data was not imported (step 5).
- **Dates are 3 hours off:** the app already uses Uganda time (`Dockerfile`). Do not change it.

## Railway instead
Create a project from the GitHub repo, add a MySQL database, and set `DB_URL` to
`jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC`,
`DB_USER` to `${{MySQL.MYSQLUSER}}` and `DB_PASSWORD` to `${{MySQL.MYSQLPASSWORD}}`. Import the data as in step 4, using Railway's public host and port.

## Back on the office PC
Nothing here changes the office system. `start.bat` still works there.
