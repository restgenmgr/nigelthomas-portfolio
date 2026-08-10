# Supabase setup for V1

1. Create a Supabase project.
2. Open SQL Editor.
3. Run `schema.sql`.
4. Enable Email authentication.
5. Create your private user account.
6. Add the six current accounts for that authenticated user:
   - canara
   - idbi
   - cash
   - paytm
   - gpay
   - phonepe
7. Add the seven current expense categories.
8. Configure the frontend with the project URL and public anon/publishable key.
9. Keep Row Level Security enabled.
10. Never expose the service-role key.

## Important production note

The supplied V1 frontend is deliberately Demo Mode. Before entering real financial information, add authentication and replace the localStorage transaction functions with authenticated Supabase calls.

The public website should not reveal account data to unauthenticated visitors.
