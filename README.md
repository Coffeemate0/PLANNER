# Together — Couples Planner PWA

A mobile-first, iOS-inspired Progressive Web App built with HTML5, CSS3, vanilla JavaScript and Supabase. The visual system is centered on **#013E37 Deep Teal** and **#FFEFB3 Soft Warm Yellow** as requested. The application structure follows the uploaded specification: Home, Calendar, Dates, Goals, More, plus Expenses, Memories, Wishlist, Tasks, Notifications and Settings. fileciteturn0file0L55-L61 fileciteturn0file0L210-L227

## Files

- `index.html` — full app UI and logic in one frontend file.
- `manifest.json` — PWA manifest, standalone display, portrait orientation and icons.
- `sw.js` — app-shell caching, offline fallback and notification click handling.
- `supabase-schema.sql` — tables, indexes, trigger, RLS, Storage policies and Realtime publication setup.
- `icons/` — PWA and Apple Home Screen icons.
- `supabase/functions/delete-account/index.ts` — optional server-side account deletion endpoint.

## 1. Create Supabase

Create a Supabase project. In **SQL Editor**, paste and run `supabase-schema.sql`.

The schema includes:

- `profiles`
- `couples`
- `events`
- `date_plans`
- `date_tasks`
- `expenses`
- `goals`
- `goal_contributions`
- `memories`
- `wishlist`
- `notifications`

All shared rows contain `couple_id`; RLS policies restrict access to the authenticated user's couple. This matches the requested one-shared-account-per-couple V1 while retaining a `profiles.user_id + couple_id` architecture for future separate partner accounts. fileciteturn0file0L30-L51 fileciteturn0file0L1035-L1053

## 2. Add Supabase credentials

Open `index.html`, near the top of the JavaScript section, and replace:

```js
const CONFIG = {
  SUPABASE_URL: 'YOUR_SUPABASE_URL',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_KEY'
};
```

Use your Supabase **Project URL** and the public **anon/publishable key**. Do not put a service-role key in frontend code. fileciteturn0file0L1454-L1468 fileciteturn0file0L1058-L1079

## 3. Supabase Auth

For the simplest V1 flow, both partners can use the same shared email and password. On registration, the SQL trigger automatically creates the couple record and profile from the sign-up metadata.

The Auth screen includes login, registration and password reset as requested. fileciteturn0file0L249-L277

If your project requires email confirmation, the user will see a confirmation message and can then log in.

## 4. Deploy

This project is static-hosting friendly. Upload the folder to Vercel, Netlify, Cloudflare Pages, GitHub Pages (with an HTTPS setup that supports your chosen Supabase redirect URL), or another static host.

For Vercel, the easiest approach is:

1. Create a new Git repository.
2. Put this project in the repository.
3. Import the repository into Vercel.
4. No build command is required.
5. Use the project URL as the Supabase Auth redirect URL where needed.

## 5. Install on iPhone / Android

Open the deployed HTTPS site in the phone browser and use **Add to Home Screen**. Because the manifest uses `display: standalone`, the installed PWA launches like an app rather than a normal browser tab. The service worker provides the cached app shell/offline opening behavior. fileciteturn0file0L948-L986

The app also includes iOS safe-area handling and touch targets designed around the requested mobile-first behavior. fileciteturn0file0L176-L206

## 6. Realtime

The frontend subscribes to Supabase Realtime for events, dates, tasks, goals, contributions, expenses, memories, wishlist items and notifications. The SQL file adds those tables to the `supabase_realtime` publication. A small status pill switches between **Synced** and **Offline**. fileciteturn0file0L879-L920

## 7. Offline support

The PWA caches the static application shell. LocalStorage caches the latest couple data, and IndexedDB holds queued inserts/updates/deletes when the device is offline. When connectivity returns, queued changes are replayed and the app reloads server data.

This is intentionally lightweight. Server-side conflict resolution beyond timestamped updates is not implemented as a full CRDT; the app avoids silently discarding queued local operations and keeps them retryable.

## 8. Notifications

The app supports:

- in-app notification center,
- browser notification permission,
- event reminder checks while the app is open,
- service-worker notification click behavior.

Browser/PWA notification availability varies by OS and browser. Full Web Push delivery requires a server-side push endpoint/VAPID setup; this project does **not** falsely assume that browser permission alone guarantees background push delivery. fileciteturn0file0L832-L850

## 9. Memories / image upload

The SQL creates a public `memories` Storage bucket and scopes object access to the couple. Photos are resized client-side before upload to reduce bandwidth/storage usage, aligning with the specification's image-compression guidance. fileciteturn0file0L718-L745

## 10. Account deletion

The built-in Settings action calls the secure `delete_my_couple_data()` RPC, which deletes the couple and all cascading shared records. Deleting the actual Supabase Auth user requires a server-side privileged call and should **never** expose a service-role key in the browser.

The included `supabase/functions/delete-account/index.ts` can be deployed as that server-side endpoint if full Auth-user deletion is required.

## 11. Main capabilities

The current build includes functional CRUD flows for events, dates, date tasks, expenses, goals and goal contributions, memories, wishlist items and love notes, plus a shared calendar, relationship counter, random date-idea generator, date budget progress, settings, dark mode, offline caching, realtime synchronization and PWA installation support. The specification calls for create/read/update/delete across major objects; the app follows that model with confirmation for destructive actions. fileciteturn0file0L1337-L1388

## 12. Notes for production hardening

Before public release, test:

- Supabase Auth redirect URLs for the exact deployed origin.
- RLS policies using two test accounts in a future multi-user setup.
- Realtime behavior after network loss/reconnect.
- Storage bucket policies and public/private image choice.
- Browser notification behavior on the iPhone/Android versions you target.
- Offline queue behavior under simultaneous edits.

The frontend intentionally contains no framework and no service-role secret.
