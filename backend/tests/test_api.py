import os
import pytest
import httpx
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.main import app
from app.core.db.base import Base
from app.core.db.session import get_db
from app.core.db.init_db import seed_demo_data

TEST_DB_FILE = "./test_rezidanspro.db"
SQLALCHEMY_DATABASE_URL = f"sqlite:///{TEST_DB_FILE}"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture(scope="session", autouse=True)
def setup_database():
    if os.path.exists(TEST_DB_FILE):
        try:
            os.remove(TEST_DB_FILE)
        except Exception:
            pass
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    seed_demo_data(db)
    db.close()
    yield
    if os.path.exists(TEST_DB_FILE):
        try:
            os.remove(TEST_DB_FILE)
        except Exception:
            pass

@pytest.fixture
async def client():
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
        yield c

async def get_auth_token(client: httpx.AsyncClient, email: str, password: str = "RezidansPro123!") -> str:
    res = await client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert res.status_code == 200, res.text
    return res.json()["access_token"]


@pytest.mark.anyio
async def test_login_manager_and_resident(client):
    """Verifies authentication for manager and resident."""
    mgr_token = await get_auth_token(client, "manager@rezidanspro.app")
    assert mgr_token is not None

    res_token = await get_auth_token(client, "resident@rezidanspro.app")
    assert res_token is not None


@pytest.mark.anyio
async def test_resident_cannot_access_manager_dues(client):
    """CRITICAL SECURITY (Sec 10, 70):
    Resident cannot call manager dues endpoint. Must return 403 Forbidden."""
    res_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_token}"}
    
    resp = await client.get("/api/v1/dues/manager?community_id=1", headers=headers)
    assert resp.status_code == 403
    assert "yönetici yetkisi" in resp.json()["detail"].lower()


@pytest.mark.anyio
async def test_manager_can_access_manager_dues(client):
    """Manager can view all dues in community."""
    mgr_token = await get_auth_token(client, "manager@rezidanspro.app")
    headers = {"Authorization": f"Bearer {mgr_token}"}
    
    resp = await client.get("/api/v1/dues/manager?community_id=1", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) >= 2


@pytest.mark.anyio
async def test_dues_privacy_resident_a_cannot_see_resident_b_due(client):
    """CRITICAL SECURITY (Sec 10, 70):
    Resident A (Necati, Apt 103, Due ID 1) tries to view Due ID 2 (Ayşe, Apt 104).
    Must return 403 Forbidden!"""
    res_a_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_a_token}"}

    # Necati views his own due (ID 1)
    resp_own = await client.get("/api/v1/dues/1", headers=headers)
    assert resp_own.status_code == 200
    assert resp_own.json()["amount"] == 2500.0

    # Necati tries to view Ayşe's due (ID 2)
    resp_other = await client.get("/api/v1/dues/2", headers=headers)
    assert resp_other.status_code == 403
    assert "yetkiniz bulunmamaktadır" in resp_other.json()["detail"].lower()


@pytest.mark.anyio
async def test_resident_my_dues_only_returns_own_apartment(client):
    """Sec 10, 22: Resident calling /dues/my only sees their own apartment dues."""
    res_a_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_a_token}"}

    resp = await client.get("/api/v1/dues/my?community_id=1", headers=headers)
    assert resp.status_code == 200
    dues = resp.json()
    assert len(dues) == 1
    assert dues[0]["apartment_no"] == "103"


@pytest.mark.anyio
async def test_resident_cannot_record_payment(client):
    """Sec 56: Resident cannot mark their own due as paid unilaterally."""
    res_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_token}"}

    resp = await client.post("/api/v1/dues/1/payments", headers=headers, json={
        "amount": 2500.0,
        "payment_method": "BANK_TRANSFER"
    })
    assert resp.status_code == 403


@pytest.mark.anyio
async def test_resident_cannot_create_announcements(client):
    """Sec 70: Normal resident cannot create an announcement."""
    res_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_token}"}

    resp = await client.post("/api/v1/announcements", headers=headers, json={
        "community_id": 1,
        "title": "İzinsiz Duyuru",
        "body": "Normal sakin duyuru yayınlayamaz."
    })
    assert resp.status_code == 403


@pytest.mark.anyio
async def test_private_message_privacy(client):
    """CRITICAL SECURITY (Sec 24, 26, 70):
    Resident B (Ayşe) cannot read the private message between Manager and Resident A (Necati)."""
    res_b_token = await get_auth_token(client, "resident2@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_b_token}"}

    # Ayşe tries to access Message ID 1 (Manager -> Necati)
    resp = await client.get("/api/v1/messages/1", headers=headers)
    assert resp.status_code == 403


@pytest.mark.anyio
async def test_resident_to_resident_messaging_is_blocked(client):
    """Sec 25: Resident -> Resident messaging is blocked to prevent social media spam."""
    res_a_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_a_token}"}

    # Necati (id=2) tries to message Ayşe (id=3)
    resp = await client.post("/api/v1/messages", headers=headers, json={
        "community_id": 1,
        "receiver_id": 3,
        "body": "Selam komşu"
    })
    assert resp.status_code == 403
    assert "yalnızca yönetici ve sakin arasında" in resp.json()["detail"].lower()


@pytest.mark.anyio
async def test_poll_duplicate_vote_prevention(client):
    """Sec 20, 85: A user cannot vote twice on the same poll."""
    res_token = await get_auth_token(client, "resident@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_token}"}

    # Necati already voted in seed data for Poll 1. Let's try voting again.
    resp = await client.post("/api/v1/polls/1/vote", headers=headers, json={"option_id": 2})
    assert resp.status_code == 400
    assert "tekrar oy veremezsiniz" in resp.json()["detail"].lower()


@pytest.mark.anyio
async def test_maintenance_resident_privacy(client):
    """Sec 18: Resident only sees their own reported maintenance requests."""
    res_b_token = await get_auth_token(client, "resident2@rezidanspro.app")
    headers = {"Authorization": f"Bearer {res_b_token}"}

    resp = await client.get("/api/v1/maintenance?community_id=1", headers=headers)
    assert resp.status_code == 200
    reqs = resp.json()
    # Ayşe only reported 1 ticket in seed data (m3: Water leak in parking)
    assert len(reqs) == 1
    assert "Otopark Tavanından Su Damlıyor" in reqs[0]["title"]


@pytest.mark.anyio
async def test_manager_dashboard_kpis(client):
    """Sec 11, 12: Manager dashboard returns aggregate KPIs."""
    mgr_token = await get_auth_token(client, "manager@rezidanspro.app")
    headers = {"Authorization": f"Bearer {mgr_token}"}

    resp = await client.get("/api/v1/dashboard/manager?community_id=1", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_apartments"] == 20
    assert data["active_residents"] == 3
    assert data["open_faults"] >= 1
