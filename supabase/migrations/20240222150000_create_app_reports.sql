-- Migration: Create App Reports Table
create table public.app_reports (
    id uuid default gen_random_uuid() primary key,
    app_id uuid references public.apps(id) on delete cascade not null,
    reporter_id uuid references public.profiles(id) on delete set null,
    reason text not null,
    details text,
    image_urls text[],
    status text default 'pending' check (status in ('pending', 'reviewed', 'resolved', 'rejected')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Configuration
alter table public.app_reports enable row level security;

-- Users can insert their own reports
create policy "Users can insert their own reports" 
on public.app_reports for insert 
with check (auth.uid() = reporter_id);

-- Admins can view all reports, users can view their own
create policy "Admins and reporters can view reports" 
on public.app_reports for select 
using (
    exists (
        select 1 from public.profiles 
        where profiles.id = auth.uid() and profiles.role = 'admin'
    )
    or auth.uid() = reporter_id
);

-- Admins can update reports (e.g., to mark as resolved/rejected)
create policy "Admins can update reports" 
on public.app_reports for update 
using (
    exists (
        select 1 from public.profiles 
        where profiles.id = auth.uid() and profiles.role = 'admin'
    )
);
