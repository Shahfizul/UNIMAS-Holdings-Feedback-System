# UNIMAS Holdings Feedback System (UHFS)

## Team Suggestify
- Lee Hao Ming (99451@siswa.unimas.my)
- Isaac Shagal Anak Tinggal (99176@siswa.unimas.my)
- Javin Sim Chuin Cai (97468@siswa.unimas.my)
- Mohamad Shahfizul Bin Mohd Suhaimi (99749@siswa.unimas.my)
- Neasthy Laade (97625@siswa.unimas.my)

## Project Overview
Digital feedback system replacing paper-based CCF for UNIMAS Holdings facilities.

## Tech Stack
- Flutter (Frontend)
- Firebase (Backend)
- Google Cloud Natural Language API (AI)

## Branch Strategy

### Main Branches
- `main` - Production ready
- `develop` - Development integration
- `testing` - QA testing

### Feature Branches (based on SRS)
- `feature/complaint-submission` (FR-01 to FR-04)
- `feature/suggestion-feedback` (FR-05 to FR-07)
- `feature/user-tracking` (FR-08 to FR-10)
- `feature/user-management` (FR-11 to FR-15)
- `feature/admin-dashboard` (FR-16 to FR-20)
- `feature/maintainer-tasks` (FR-21 to FR-24)
- `feature/reporting-analytics` (FR-25 to FR-26)
- `feature/ai-priority-analysis` (FR-27)
- `feature/notifications` (FR-28)

### UI Branches
- `ui/resident-mobile`
- `ui/admin-web`
- `ui/maintainer-mobile`

## Getting Started
1. Clone repository
2. Checkout `develop` branch
3. Create feature branch: `git checkout -b feature/your-feature`
4. Develop and test
5. Create PR to `develop`
6. After review, merge to `develop`
7. Regular releases to `main`

## Development Guidelines
- Follow Flutter conventions
- Write tests for new features
- Update documentation
- Use PR templates for all merges
