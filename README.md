# HPS Connect

হেরিটেজ পাবলিক স্কুল, ফরিদপুর-এর প্রায় ১৫০ জন শিক্ষক ও স্টাফের জন্য যোগাযোগ অ্যাপ।
Flutter + Firebase (Authentication, Cloud Firestore, Cloud Messaging)।

- প্যাকেজ নাম (applicationId): `com.hps.connect`
- প্রথম লক্ষ্য: Android (Google Play)

## ছয়টি রোল

| Firestore `role` মান | রোল |
|---|---|
| `principal` | প্রিন্সিপাল |
| `junior_incharge` | জুনিয়র সেকশন ইনচার্জ |
| `high_incharge` | হাই সেকশন ইনচার্জ |
| `residential_incharge` | আবাসিক ইনচার্জ |
| `super_admin` | সুপার অ্যাডমিন |
| `teacher` | শিক্ষক/স্টাফ |

কোডে: `lib/models/user_role.dart`। সিকিউরিটি রুলস: `firebase/firestore.rules`।

## প্রথম APK বানানো (সবচেয়ে কম সেটআপে)

কোনো Secret ছাড়াই GitHub Actions APK বানায়। **Actions → Android build → সর্বশেষ রান → Artifacts**
থেকে zip নামিয়ে `hps-connect-…-release.apk` ফোনে ইনস্টল করুন।
Secret ছাড়া বানানো APK খুললে "Firebase সেটআপ বাকি" স্ক্রিন দেখাবে, লগইন কাজ করবে না।
লগইন চালু করতে নিচের ধাপ ১ ও ২ করুন।

### ধাপ ১: Firebase প্রজেক্ট

1. https://console.firebase.google.com এ নতুন প্রজেক্ট খুলুন (যেমন `hps-connect`)।
2. **Add app → Android**, package name দিন `com.hps.connect`। `google-services.json` ডাউনলোড করুন।
3. **Authentication → Sign-in method → Email/Password** চালু করুন।
4. **Firestore Database → Create database** (অঞ্চল: `asia-south1` বা কাছের কোনোটি)।
5. **Firestore → Rules**-এ `firebase/firestore.rules` ফাইলের লেখা পেস্ট করে Publish করুন
   (অথবা Firebase CLI দিয়ে `firebase deploy --only firestore`)।

### ধাপ ২: প্রথম সুপার অ্যাডমিন

রুলস অনুযায়ী শুধু সুপার অ্যাডমিন ব্যবহারকারী তৈরি করতে পারে, তাই প্রথমজনকে হাতে বানাতে হবে:

1. **Authentication → Users → Add user**: ইমেইল ও পাসওয়ার্ড দিন। তৈরি হলে তার **User UID** কপি করুন।
2. **Firestore → Start collection** `users`, Document ID = সেই UID, ফিল্ড:
   - `name` (string): নাম
   - `email` (string): ইমেইল
   - `role` (string): `super_admin`
   - `active` (boolean): `true`
3. বাকি স্টাফদের জন্য একইভাবে Authentication-এ ইউজার তৈরি করে `users/{uid}` ডকুমেন্টে উপযুক্ত `role` দিন।
   (অ্যাপের ভেতরে অ্যাডমিন প্যানেল পরের ধাপে আসবে।)

ঐচ্ছিক: `roles` কালেকশনে `firebase/seed/roles.json`-এর মানগুলো রাখতে পারেন।

## GitHub Secrets

**Settings → Secrets and variables → Actions → New repository secret**-এ এগুলো যোগ করুন:

| Secret | কী দিতে হবে | না দিলে কী হবে |
|---|---|---|
| `GOOGLE_SERVICES_JSON_BASE64` | `google-services.json` ফাইলের base64 | APK বানাবে, কিন্তু Firebase কাজ করবে না |
| `ANDROID_KEYSTORE_BASE64` | রিলিজ কীস্টোর (`.jks`) ফাইলের base64 | debug কী দিয়ে সাইন হবে; Play Store-এ দেওয়া যাবে না |
| `ANDROID_KEYSTORE_PASSWORD` | কীস্টোরের পাসওয়ার্ড | |
| `ANDROID_KEY_ALIAS` | কী-এর alias (যেমন `upload`) | |
| `ANDROID_KEY_PASSWORD` | কী-এর পাসওয়ার্ড | |

base64 বানানো:

```bash
# Linux / macOS
base64 -w 0 google-services.json        # macOS-এ: base64 -i google-services.json
base64 -w 0 upload-keystore.jks
```

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("google-services.json"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

রিলিজ কীস্টোর একবারই বানাতে হয় (Java/Android Studio থাকলে):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

> **সতর্কতা:** কীস্টোর ফাইল ও পাসওয়ার্ড নিরাপদে ব্যাকআপ রাখুন। হারালে Play Store-এ আপডেট দেওয়া কঠিন হয়ে যায়।
> `google-services.json`, `.jks` ও `key.properties` কখনো রিপোতে কমিট করবেন না (`.gitignore`-এ আছে)।

## বিল্ড ও রিলিজ (GitHub Actions)

`.github/workflows/android.yml` প্রতিটি push, pull request ও হাতে চালানো (Run workflow) রানে:
`flutter analyze`, `flutter test`, তারপর debug APK, release APK ও release AAB বানিয়ে Artifacts-এ রাখে।

নতুন ভার্সন রিলিজ করতে ট্যাগ পুশ করুন:

```bash
git tag v1.0.0
git push origin v1.0.0
```

তখন একটি **GitHub Release** তৈরি হবে, তাতে APK ও AAB ফাইল থাকবে। AAB ফাইলটি Google Play Console-এ আপলোড করুন।
versionCode স্বয়ংক্রিয়ভাবে GitHub রান নম্বর থেকে নেওয়া হয়।

## লোকাল ডেভেলপমেন্ট

```bash
flutter pub get
# android/app/google-services.json রাখুন
flutter run
```

## প্রজেক্ট কাঠামো

```
lib/
  main.dart                  Firebase চালু করা, অ্যাপের শুরু
  theme.dart
  models/user_role.dart      ছয়টি রোল ও অনুমতি
  models/app_user.dart       users/{uid} ডকুমেন্ট
  services/auth_service.dart লগইন, লগআউট, পাসওয়ার্ড রিসেট
  services/push_service.dart FCM টোকেন সংরক্ষণ
  screens/                   লগইন, হোম (রোলভিত্তিক), সেটআপ স্ক্রিন
firebase/
  firestore.rules            সিকিউরিটি রুলস
  seed/roles.json
```

## পরবর্তী কাজ

নোটিশ ও জরুরি সতর্কবার্তা, পড়া/স্বীকৃতি ট্র্যাকিং, চ্যাট, পোল, টাস্ক, মিটিং, ছুটির আবেদন,
ডকুমেন্ট (Firebase Storage), প্রিন্সিপালের ড্যাশবোর্ড, সুপার অ্যাডমিন প্যানেল,
এবং নোটিফিকেশন পাঠানোর Cloud Functions।
