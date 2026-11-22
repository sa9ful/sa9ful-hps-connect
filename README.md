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

Secret ছাড়া বানানো APK **ডেমো মোডে** চলে: যেকোনো আইডি দিয়ে Login চাপলে নমুনা ডেটা দিয়ে
সব স্ক্রিন (নোটিশ, চ্যাট, মিটিং, টাস্ক, ছুটির আবেদন, প্রিন্সিপাল ড্যাশবোর্ড) ঘুরে দেখা যায়।
কোনো ডেটা সার্ভারে যায় না। আসল লগইন ও ডেটার জন্য নিচের ধাপ ১ ও ২ করুন।

## স্ক্রিন (ডিজাইন অনুযায়ী)

Splash, Login (User ID/Email, Google), Role Selection, Teacher Home, Principal Dashboard,
Side Menu, Notice Board, Notice Details (স্বীকৃতি ও Viewed গণনা), Chat (Personal/Group),
Meetings, Tasks, Leave Application। এছাড়া Directory, Send Notice, Schedule Meeting, Assign Task।
Documents, Events, Polls, Reports, Profile, Settings এখন "শীঘ্রই আসছে" স্ক্রিন দেখায়।

ডিজাইন থেকে নেওয়া কিছু অনুমান:

- **লোগো** (`assets/images/logo.png`, অ্যাপ আইকন) ডিজাইনের ছবি থেকে কেটে নেওয়া, তাই একটু ঝাপসা।
  আসল লোগোর PNG (অন্তত 512×512) দিলে বদলে দেওয়া যাবে। Splash-এ স্কুল ভবনের ছবির জায়গায় আপাতত আইকন।
- **User ID** দিয়ে লগইন: '@' ছাড়া আইডি লিখলে `আইডি@hps.edu.bd` ইমেইল ধরা হয়
  (`lib/data/backend.dart`-এর `kUserIdEmailDomain`)। স্কুলের আসল ডোমেইন হলে সেটা বসান।
- **Role Selection**: লগইনের পর দেখায়; শুধু Firestore-এ দেওয়া রোলগুলো চাপা যায় (নিরাপত্তার জন্য,
  কেউ নিজে রোল বেছে প্রিন্সিপাল হতে পারবে না)। কারো একাধিক দায়িত্ব থাকলে `roles` অ্যারেতে দিন।
- প্রিন্সিপাল ও সুপার অ্যাডমিন Principal Dashboard পান; বাকিরা Teacher Home।
  ইনচার্জরা নোটিশ পাঠাতে ও মিটিং ডাকতে পারেন।
- "Staff" গণনা: যাদের `department` = `Staff`; বাকিরা Teachers।

## releases রিপোতে অটো-প্রকাশ ও অ্যাপে আপডেট

প্রতিটি রিলিজে GitHub Actions আলাদা পাবলিক রিপো `sa9ful/hps-connect-releases`-এ `build-bot` নামে
"Release x.y.z" কমিট করে: `HPS-Connect-x.y.z.apk`, `HPS-Connect-latest.apk`, `README.md`
(সর্বশেষ ডাউনলোড লিংক) ও `version.json`।

একবারের সেটআপ:

1. খালি পাবলিক রিপো খুলুন: https://github.com/new?name=hps-connect-releases&visibility=public
2. Fine-grained token বানান (শুধু ওই রিপো, **Contents: Read and write**), তারপর এই রিপোর
   **Settings → Secrets and variables → Actions**-এ `RELEASES_REPO_TOKEN` নামে রাখুন।
   (অন্য রিপো নাম চাইলে Actions variable `RELEASES_REPO` দিন।)
3. রিলিজ কীস্টোরের Secret-গুলো (নিচে) দিন। না দিলে প্রতিবার আলাদা debug কী-তে সাইন হয়, ফলে নতুন APK
   পুরনোটার ওপর ইনস্টল হবে না।

রিলিজ করতে: `v1.0.1` ধরনের ট্যাগ push করুন, অথবা **Actions → Android build → Run workflow**-এ
ভার্সন ও "কী নতুন" লিখে চালান।

অ্যাপ চালুর পর `version.json` পড়ে; সেখানের `build_number` অ্যাপের চেয়ে বড় হলে "নতুন আপডেট এসেছে"
ডায়ালগ দেখায়, "ডাউনলোড" চাপলে ব্রাউজারে নতুন APK নামে (`lib/services/update_service.dart`)।

### ধাপ ১: Firebase প্রজেক্ট

1. https://console.firebase.google.com এ নতুন প্রজেক্ট খুলুন (যেমন `hps-connect`)।
2. **Add app → Android**, package name দিন `com.hps.connect`। `google-services.json` ডাউনলোড করুন।
3. **Authentication → Sign-in method → Email/Password** চালু করুন।
   Google লগইনের জন্য **Google** প্রোভাইডারও চালু করুন এবং **Project settings → Your apps → Android**-এ
   রিলিজ কীস্টোরের SHA-1 ও SHA-256 যোগ করুন (`keytool -list -v -keystore upload-keystore.jks -alias upload`)।
   Google দিয়ে ঢুকলেও `users/{uid}` প্রোফাইল লাগবে, না থাকলে "অ্যাকাউন্ট চালু হয়নি" দেখাবে।
4. **Firestore Database → Create database** (অঞ্চল: `asia-south1` বা কাছের কোনোটি)।
5. **Firestore → Rules**-এ `firebase/firestore.rules` ফাইলের লেখা পেস্ট করে Publish করুন
   (অথবা Firebase CLI দিয়ে `firebase deploy --only firestore`, এতে `firestore.indexes.json`-এর index-ও যায়)।

### ধাপ ২: প্রথম সুপার অ্যাডমিন

রুলস অনুযায়ী শুধু সুপার অ্যাডমিন ব্যবহারকারী তৈরি করতে পারে, তাই প্রথমজনকে হাতে বানাতে হবে:

1. **Authentication → Users → Add user**: ইমেইল ও পাসওয়ার্ড দিন। তৈরি হলে তার **User UID** কপি করুন।
2. **Firestore → Start collection** `users`, Document ID = সেই UID, ফিল্ড:
   - `name` (string): নাম
   - `email` (string): ইমেইল
   - `role` (string): `super_admin`
   - `active` (boolean): `true`
   - ঐচ্ছিক: `department` (string, যেমন `Science`, `Staff`), `section` (`junior`/`high`/`residential`),
     `roles` (array, অতিরিক্ত রোল)
3. বাকি স্টাফদের জন্য একইভাবে Authentication-এ ইউজার তৈরি করে `users/{uid}` ডকুমেন্টে উপযুক্ত `role` দিন।
   (অ্যাপের ভেতরে অ্যাডমিন প্যানেল পরের ধাপে আসবে।)

ঐচ্ছিক: `roles` কালেকশনে `firebase/seed/roles.json`-এর মানগুলো রাখতে পারেন।

## Firestore ডেটা

| কালেকশন | মূল ফিল্ড |
|---|---|
| `users/{uid}` | name, email, role, roles[], department, section, active, fcmTokens[] |
| `notices/{id}` | title, body, important, section, authorId, authorName, authorRole, createdAt, attachments[] |
| `notices/{id}/reads/{uid}` | uid, name, viewedAt, acknowledgedAt |
| `meetings/{id}` | title, startAt, location, createdBy, joined[] |
| `tasks/{id}` | title, dueAt, assigneeId, assignedById, done |
| `chats/{id}` | name, type (`personal`/`group`), members[], lastMessage, lastAt, unread{uid: n} |
| `chats/{id}/messages/{id}` | text, senderId, senderName, sentAt |
| `leaveRequests/{id}` | userId, userName, type, from, to, reason, status |

নতুন চ্যাট/গ্রুপ খোলার স্ক্রিন এখনো নেই; আপাতত Firebase Console থেকে `chats` ডকুমেন্ট বানান।

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
  main.dart                    Firebase চালু করা (না পারলে ডেমো মোড)
  app_state.dart               বেছে নেওয়া রোল ও ব্যাকএন্ড
  theme.dart                   নীল থিম
  data/backend.dart            ডেটা ইন্টারফেস
  data/firebase_backend.dart   Firebase Auth + Firestore
  data/demo_backend.dart       নমুনা ডেটা
  data/models.dart             Notice, Meeting, Task, Chat ...
  models/user_role.dart        ছয়টি রোল ও অনুমতি
  services/push_service.dart   FCM টোকেন সংরক্ষণ
  screens/                     ১২টি স্ক্রিন
  widgets/common.dart          লোগো, ট্যাব, টাইল, ব্যাজ
firebase/
  firestore.rules            সিকিউরিটি রুলস
  seed/roles.json
```

## পরবর্তী কাজ

জরুরি সতর্কবার্তা, নতুন চ্যাট/গ্রুপ খোলা, পোল, ইভেন্ট, ডকুমেন্ট ও নোটিশের ফাইল (Firebase Storage),
ছুটির আবেদন অনুমোদন, Viewed তালিকা, রিপোর্ট, প্রোফাইল, সুপার অ্যাডমিন প্যানেল (ইউজার তৈরি),
এবং নোটিফিকেশন পাঠানোর Cloud Functions।
