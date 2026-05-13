# Comandix SaaS — Detailed Project State Report

**Date:** May 12, 2026
**Target Audience:** AI Code Assistants, Technical Leads, System Architects
**Project Type:** Multi-tenant Point of Sale (POS) & Restaurant Management SaaS.

---

## 1. Executive Summary
Comandix is an enterprise-grade, multi-tenant POS platform built for the restaurant industry. The system is designed with a cloud-first backend and an offline-capable, high-performance desktop client. It supports real-time kitchen dispatching (KDS), hardware-level ESC/POS ticket printing over LAN, and complex visual floor plans.

## 2. Technology Stack
### Backend (Cloud)
*   **Framework:** NestJS (Node.js 20 LTS)
*   **Language:** TypeScript
*   **Database:** PostgreSQL 15 (Relational Data)
*   **Caching & Pub/Sub:** Redis 7 (WebSockets & Sessions)
*   **ORM:** TypeORM
*   **Authentication:** Passport.js (JWT Strategy) + bcrypt
*   **Real-time:** Socket.io (NestJS Gateways)

### Frontend (Desktop POS Client)
*   **Framework:** Flutter (Windows Desktop Target)
*   **Language:** Dart 3.x
*   **State Management:** BLoC (`flutter_bloc`)
*   **Networking:** Dio (`dio`)
*   **Local DB (Offline-first):** Drift (SQLite)
*   **Hardware Integration:** Raw TCP Sockets (`dart:io`), ESC/POS byte generators (`esc_pos_utils_plus`)
*   **UI/UX:** Custom "Slate/Cyberpunk" premium aesthetic, Glassmorphism, Micro-animations.

### Infrastructure & Deployment
*   **Hosting:** Ubuntu 22.04 VPS (IP: `186.64.123.116`)
*   **Containerization:** Docker & Docker Compose
*   **Reverse Proxy:** Nginx (Alpine) handling standard HTTP and WebSocket Upgrades.
*   **CI/CD:** GitHub Repository (`Scribax/Comandix`) synced via custom bash setup scripts.

---

## 3. Database Schema Architecture (PostgreSQL)
The database enforces strict tenant isolation using a `restaurantId` UUID foreign key on all domain entities.

1.  **`restaurants`**: The root tenant entity. `(id, name, slug, timezone)`
2.  **`users`**: RBAC system (admin, cajero, mesero). `(id, restaurantId, name, email, passwordHash, role)`
3.  **`sectors`**: Floor plan logical grouping (e.g., "Terraza", "Salón"). `(id, restaurantId, name)`
4.  **`tables`**: Physical tables with 2D coordinates for visual mapping. `(id, sectorId, name, status, shape, posX, posY, width, height)`
5.  **`product_categories`**: Catalog taxonomy. `(id, restaurantId, name, color)`
6.  **`products`**: Inventory items. `(id, categoryId, name, price, stock, isKitchen)`
7.  **`orders`**: The core transaction logic. `(id, restaurantId, tableId, userId, status, total, paymentMethod)`
8.  **`order_items`**: Nested array of products per order. `(id, orderId, productId, quantity, unitPrice, notes, sentToKitchen)`
9.  **`printers`**: Hardware registry. `(id, restaurantId, name, type, ipAddress, port)`
10. **`printer_routes`**: Mapping categories to specific printers (e.g., "Bebidas" -> Bar Printer). `(id, categoryId, printerId)`

---

## 4. Current Implementation Status

### 🟢 Backend (100% Completed for MVP)
The API is live, dockerized, and accessible in production.
*   **Auth Module:** Fully operational. JWT generation, Bcrypt hashing, and strict endpoint protection via `JwtAuthGuard`.
*   **Tenant Security:** A custom `@TenantId()` decorator extracts the `restaurantId` from the JWT, guaranteeing that a user can only query or mutate data belonging to their specific restaurant.
*   **CRUD Modules:** Completed for all entities (`Sectors`, `Tables`, `Catalog`, `Reports`).
*   **Orders Service:** Contains complex business logic for opening tables, calculating totals, marking tables as `waiting_payment`, and closing checks.
*   **Kitchen Gateway (WebSockets):** Dispatches real-time events (`orderCreated`, `itemUpdated`) to KDS clients.
*   **Printers Service:** Routing logic that evaluates `printer_routes` to dispatch specific order items directly to LAN printers via TCP.

### 🟡 Frontend Flutter (70% Completed)
The UI architecture and visual language are fully established. The app successfully runs natively on Windows.
*   **Networking Layer:** `ApiClient` configured with Interceptors for JWT injection. Connected to live VPS.
*   **Auth Flow:** `LoginScreen` and `AuthBloc` fully integrated. Successfully authenticates against the live API.
*   **Main POS UI:** Highly polished, responsive dashboard built. Features:
    *   Dynamic Sidebar with routing placeholders.
    *   Glassmorphic `TableCard` grid with dynamic status colors (Free, Occupied, Waiting Payment) and pulse animations.
    *   Sliding `OrderPanel` (Cart Drawer) with category filters, product grid, and checkout actions.
*   **Hardware Layer:** `LanPrinter` TCP class and ESC/POS generator implemented.
*   **Pending (Next Steps):**
    *   Replace hardcoded UI Mock Data in the `PosMainScreen` and `OrderPanel` with real BLoC state fetching data from the API (`Dio` requests to `/tables`, `/products`).
    *   Implement the `Drift` local SQLite synchronization layer for offline resilience.
    *   Wire the "Enviar a Cocina" and "Cobrar Mesa" buttons to the `/api/v1/orders` endpoints.

---

## 5. Known Context & Infrastructure Nuances
*   **Docker Network:** Services communicate via Docker internal DNS. The NestJS API connects to Postgres via `DB_HOST=db`.
*   **Node.js Version:** Upgraded to Node 20 LTS Alpine to support global `crypto.randomUUID()` required by TypeORM.
*   **Sync:** `synchronize: true` is currently controlled via a `DB_SYNC=true` environment variable to allow production schema updates without manual migrations during the MVP phase.
*   **First Tenant:** A root tenant (`Mi Restaurante`) and admin user (`admin@comandix.com` / `password`) were injected manually via `psql` to bootstrap the system.

---
*Generated by Antigravity Assistant.*
