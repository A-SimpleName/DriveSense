import http from "../api/httpService";
import type { Account } from "../model/account";

export const getAllAccounts = () => http.get<Account[]>("/accounts");
export const getAccountById = (id: number) => http.get<Account>(`/accounts/${id}`);
export const createAccount = (account: Omit<Account, "id">) => http.post("/accounts", account);
export const updateAccount = (id: number, account: Omit<Account, "id">) => http.put(`/accounts/${id}`, account);
export const deleteAccount = (id: number) => http.delete(`/accounts/${id}`);