export const tokenService = {
  setTokens: (data: {
    accountToken?: string;
    profileToken?: string;
    refreshToken?: string;
  }) => {
    if (data.accountToken) {
      localStorage.setItem("accountToken", data.accountToken);
    }

    if (data.profileToken) {
      localStorage.setItem("profileToken", data.profileToken);
    }

    if (data.refreshToken) {
      localStorage.setItem("refreshToken", data.refreshToken);
    }
  },

  getAccessToken: () => {
    return (
      localStorage.getItem("profileToken") ||
      localStorage.getItem("accountToken")
    );
  },

  getAccountToken: () => {
    return localStorage.getItem("accountToken");
  },

  getRefreshToken: () => {
    return localStorage.getItem("refreshToken");
  },

  clear: () => {
    localStorage.removeItem("accountToken");
    localStorage.removeItem("profileToken");
    localStorage.removeItem("refreshToken");
  }
};