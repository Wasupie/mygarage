# Supabase Configuration Guide

## Step 1: Get Your Supabase Credentials

1. Go to [https://app.supabase.com](https://app.supabase.com)
2. Select your project (or create a new one)
3. Go to **Settings** → **API**
4. Copy the following values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (the public API key)

## Step 2: Update Configuration File

Open `lib/config/supabase_config.dart` and replace:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

With your actual credentials:

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'your-actual-anon-key-here';
```

## Step 3: Set Up Database

1. Go to **SQL Editor** in your Supabase dashboard
2. Open the `supabase_schema.sql` file in this project
3. Copy all the SQL code
4. Paste it into the Supabase SQL Editor
5. Click **Run** to create all tables and security policies

## Step 4: Enable Authentication

1. Go to **Authentication** → **Providers** in Supabase
2. Enable **Email** provider
3. Configure email templates if needed

## Step 5: Run the App

```bash
flutter pub get
flutter run
```

## Security Notes

⚠️ **IMPORTANT:**
- The `anon key` is safe to use in client apps
- Never commit real API keys to public repositories
- Consider using environment variables for production:
  - Create `.env` file (add to `.gitignore`)
  - Use `flutter_dotenv` package to load variables

## Alternative: Using Environment Variables (Production Ready)

### 1. Add to pubspec.yaml:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

### 2. Create `.env` file:
```
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=your-key-here
```

### 3. Update supabase_config.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
}
```

### 4. Load in main.dart:
```dart
void main() async {
  await dotenv.load();
  runApp(const MyGarageApp());
}
```

### 5. Add to .gitignore:
```
.env
```

## Testing the Connection

Run the app and check the debug console for connection status. If you see any errors related to Supabase, verify:

1. ✅ URL and API key are correct
2. ✅ Database tables are created
3. ✅ Row Level Security policies are in place
4. ✅ User is authenticated (required for RLS)

## Next Steps

The app is now configured to use Supabase! All data will be stored in the cloud and automatically synced across devices when users sign in.
