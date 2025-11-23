# Personal Trainer Database (PostgreSQL)

This project implements a complete relational database for a personal trainer, including clients, workouts, schedules, payments, progress tracking, and analytical queries.
The system includes user roles, security rules, data population scripts, and advanced analytics written in SQL.

## 📌 Features

✔ Clients & Trainers
Store client and trainer profiles
Track goals, notes, demographics, and assigned trainers

## ✔ Scheduling System

Trainer schedules with availability
Client booking slots
Sessions with types, duration, and status tracking

## ✔ Progress Tracking

Body measurements
Weight logs
Time-based analytics

## ✔ Payments & Discounts

Payment history
Package system (sessions, prices, validity)
Discounts and promotion logic

## ✔ Reviews & News

Client reviews
Trainer news posts with unique constraints

## ✔ Countries & Phone Codes

Normalized reference table for international clients

## 🛠 Technologies Used

Docker — creates and runs the PostgreSQL environment
DBeaver — used to develop the schema, write SQL, and inspect data
Lucidchart — used for ER-diagram and database visualization
PostgreSQL — main database engine

## 📜 What the SQL Script Includes

**1. Role & User Management**

Creation of three users: `sport_admin`, `sport_trainer`, `sport_client`.
Schema-level and table-level permissions.
Restricted access with GRANT/REVOKE rules.
Preparation for possible RLS (Row-Level Security).

**2. Schema Creation**

All objects are created inside the schema: sport.

Tables include:
`country`
`trainer`
`client`
`progress`
`schedule_trainer`
`schedule_client`
`session`
`news`
`package`
`payment`
`discount`

All with foreign keys, cascading rules, unique constraints, and primary keys.

**3. Data Population (Randomized)**

The script automatically generates:
`100+ clients`
`200 progress records`
`30 trainer schedule days`
`80 scheduled bookings + 50 more unique bookings`
`50 packages + additional coverage for missing clients`
`50 training sessions`
`20 mixed news items`
`20 randomized reviews with shuffled ratings`
`5 discounts`
`50 payments`

Randomization uses arrays, generate_series, random(), unnest, and cross joins.

**4. Role Permissions**

Examples:
Role	                    Permissions
`sport_admin`	            full control over schema
`sport_trainer`	          read clients, add news, manage schedules
`sport_client`	          book sessions, track progress, create reviews

Public access is fully revoked.

**5. Analytics & Statistics**

- Advanced SQL for reporting:
  
- Revenue and discount analysis
  
- Revenue by country
  
- Session type summary
- Session location distribution (gym / online / outdoor)
- Payment history with LAG()
- Next session reminder using LEAD()
- Completed session revenue metrics

These queries demonstrate the database’s analytical capability.
