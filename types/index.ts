export type LeadStatus = "new" | "contacted" | "booked" | "visited" | "disqualified" | "closed";
export type LeadPriority = "hot" | "warm" | "cold";
export type UserRole = "admin" | "makelaar";

export interface Profile {
  id: string;
  organization_id: string | null;
  full_name: string;
  initials: string;
  email: string;
  phone: string | null;
  role: UserRole;
  color: string;
  avatar_url: string | null;
  created_at: string;
}

export interface Lead {
  id: string;
  organization_id: string;
  name: string;
  email: string | null;
  phone: string | null;
  message: string | null;
  status: LeadStatus;
  priority: LeadPriority;
  score: number;
  created_at: string;
}
