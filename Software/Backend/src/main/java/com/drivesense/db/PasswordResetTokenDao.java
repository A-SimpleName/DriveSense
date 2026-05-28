package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.PasswordResetToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Repository
public class PasswordResetTokenDao {
    @Autowired
    private DbConnection dbConnection;

    public void insert(PasswordResetToken token) {
        String sql = "INSERT INTO password_reset_token (account_id, code_hash, expires_at) VALUES (?, ?, ?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, token.getAccountId());
            ps.setString(2, token.getCodeHash());
            ps.setObject(3, token.getExpiresAt());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Speichern des Reset-Tokens", e);
        }
    }

    public List<PasswordResetToken> getAllValidByAccount(int accountId) {
        String sql = """
            SELECT * FROM password_reset_token
            WHERE account_id = ? AND used = false AND expires_at > NOW()
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ResultSet rs = ps.executeQuery();
            List<PasswordResetToken> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Reset-Tokens", e);
        }
    }

    public void markAsUsed(int id) {
        String sql = "UPDATE password_reset_token SET used = true WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Reset-Tokens", e);
        }
    }

    private PasswordResetToken map(ResultSet rs) throws SQLException {
        PasswordResetToken token = new PasswordResetToken();
        token.setId(rs.getInt("id"));
        token.setAccountId(rs.getInt("account_id"));
        token.setCodeHash(rs.getString("code_hash"));
        token.setUsed(rs.getBoolean("used"));
        token.setExpiresAt(rs.getObject("expires_at", LocalDateTime.class));
        token.setCreatedAt(rs.getObject("created_at", LocalDateTime.class));
        return token;
    }
}
