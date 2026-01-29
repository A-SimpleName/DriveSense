export function logout() {
     localStorage.removeItem("token");
}

export function login() {
    localStorage.setItem("token","prototype")
}

export function isAuthenticated(): boolean {
    return !!localStorage.getItem("token");
}

export function SignUp() {
    // Placeholder function for sign-up logic
}