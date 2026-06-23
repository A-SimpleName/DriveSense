export interface Profile {
    id?: number;
    name: string;
    role: string;
    account_id: number;
    joinable?: boolean;
    joinMessage?: string | null;
    requiredRole?: string | null;
}
