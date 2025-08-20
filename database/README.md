# Database

This folder holds SQL assets for the ClearKhong project.

- `schema.sql` — full DDL to create/update tables and types.
- (optional) `seed.sql` — if you add one, `backend/scripts/init_db.js` will still run fine; seeding is done by `backend/scripts/seed_db.js`.

## How it's wired

Backend scripts read `database/schema.sql` with a relative path from the backend:
- `backend/scripts/init_db.js` uses `path.resolve(__dirname, '../../database/schema.sql')`

Configure DB connection in `backend/.env`:

```
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=postgres
DB_PASS=
DB_NAME=clearkhong
```

Run (from `backend/`):

```
npm install
npm run init:db
npm run seed:db
npm run dev
```
