BUILDTRACK PRO - FUNCTIONAL MODULE PATCH

Copy the files in this archive over the matching files in your existing local project:

frontend/lib/screens/module_screen.dart
frontend/lib/services/auth_service.dart

Do NOT replace your .git folder or Dockerfile.

After copying:
1. cd frontend
2. flutter pub get
3. flutter build web
4. cd ..
5. git status
6. git add frontend/lib/screens/module_screen.dart frontend/lib/services/auth_service.dart
7. git commit -m "Connect functional modules to API"
8. git push origin main

Railway should then auto-deploy the frontend service from the new GitHub commit.
