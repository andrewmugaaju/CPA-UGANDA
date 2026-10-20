# Putting CPA Uganda on Railway

This guide moves the system from the office PC to Railway. Read the three warnings first.

## Three warnings

1. **A paid plan.** The free trial is not meant for a real system. Use a paid plan, so the system and the member data are not switched off.
   Check the current price on railway.com before you start.
2. **Member data leaves the office.** Names, phone numbers and balances will sit on Railway's servers abroad. Make sure CPA agrees, and
   keep a backup copy at the office too (step 8).
3. **Never put passwords or database dumps in GitHub.** The `.gitignore` already keeps `backups`, `DOCS`, `.sql` and `.xlsx` files out.
   Type passwords only into Railway's Variables page.

## Steps

### 1. Make a backup of the office database
In PowerShell, in the project folder:

```powershell
C:\xampp\mysql\bin\mysqldump.exe -uroot --single-transaction cpa_uganda > backups\cpa_uganda_for_railway.sql
```

### 2. Create the project on Railway
1. Sign in at railway.com and choose a paid plan.
2. **New Project → Deploy from GitHub repo → `andrewmugaaju/CPA-UGANDA`.**
3. Railway finds the `Dockerfile` and builds the app. The first build takes a few minutes and will fail to start until the database is ready. That is fine.

### 3. Add the database
1. In the project: **New → Database → MySQL**. Keep its name `MySQL`.
2. Open the MySQL service → **Variables** and keep the page open: it lists the host, port, user and password.

### 4. Move the data into it (before the app starts)
1. Open the MySQL service → **Connect → Public Network** and note the host, the port and the password.
2. In PowerShell (it asks for the password, so it is not written anywhere):

```powershell
C:\xampp\mysql\bin\mysql.exe -h HOST -P PORT -uroot -p railway < backups\cpa_uganda_for_railway.sql
```

The office database is MariaDB and Railway's is MySQL. This usually imports without trouble. If it prints an error, send me the message.

### 5. Tell the app where its database is
Open the app service → **Variables** and add (the `${{MySQL...}}` parts are filled in by Railway, type them exactly):

| Name | Value |
|---|---|
| `DB_URL` | `jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC` |
| `DB_USER` | `${{MySQL.MYSQLUSER}}` |
| `DB_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` |

`PORT` is set by Railway itself. Because you restored the office database, the logins (`admin`, `support`) and their passwords came with it.
Starting from an empty database instead? Also add `CPA_ADMIN_PASSWORD` and `MANAGER_PASSWORD` with passwords of your choice.

### 6. Start it and open it
1. Open the app service → **Settings → Networking → Generate Domain**.
2. Redeploy. When the log shows "Started SaccoApplication", open the address and sign in as `admin`.
3. Check: Members, Loans, Savings interest, and the Trial balance (it should say Balanced).

### 7. Keep it safe
- Change the `admin` and `support` passwords with "Change password".
- Do not share the Railway address publicly: it is the live system.

### 8. Back up, every week
Use the same two commands in step 1 and step 4, but reversed: dump from Railway's public address into a file and keep it at the office.

```powershell
C:\xampp\mysql\bin\mysqldump.exe -h HOST -P PORT -uroot -p --single-transaction railway > backups\railway_backup.sql
```

## Going back to the office PC
Nothing here changes the office system. `start.bat` still works there.
