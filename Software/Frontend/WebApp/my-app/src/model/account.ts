export interface Account {
    id: number;
    fname: string;
    lname: string;
    email: string;
    pwd: string;
    created_at: Date;
}

export interface AccountResponse {
    id: number;
    fname: string;
    lname: string;
    email: string;
    created_at: Date;
}