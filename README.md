# ClearKhong

Frontend: http://127.0.0.1:8080
Backend:  http://127.0.0.1:4000
Swagger:  http://127.0.0.1:4000/docs

## Run
docker compose up -d --build (first time only)
docker compose up -d (next time using this instead)

## Stop Docker
docker compose down

## Notes
- DB data persists in volume `pgdata` (อย่าใช้ `docker compose down -v` หากไม่ต้องการลบข้อมูล)
- Uploaded files persist in volume `uploads-data`
- ถ้าพอร์ต 5432 ชน ให้คงคอมเมนต์ ports ของ db ตามไฟล์นี้ไว้ (ไม่จำเป็นต้อง expose ออก host)