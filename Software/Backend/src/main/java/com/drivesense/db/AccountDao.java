package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.*;
import com.drivesense.model.Account;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class AccountDao {

    @Autowired
    private DbConnection dbConnection;

    public Account insert(Account acc) {
        String sql = "INSERT INTO account (first_name, last_name, pwd, email, birthdate) VALUES (?,?,?,?, ?)";
        try (Connection conn = dbConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1,acc.getFirstName());
            ps.setString(2,acc.getLastName());
            ps.setString(3,acc.getPassword());
            ps.setString(4,acc.getEmail());
            if (acc.getBirthdate() != null) {
                ps.setDate(5, Date.valueOf(acc.getBirthdate()));
            } else {
                ps.setNull(5, Types.DATE);
            }

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) acc.setId(rs.getInt(1));
            return acc;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Speichern des Accounts", e);
        }
    }

    // ── Lesen ───────────────────────────────────────────────────────────────

    /** Liefert aktiven (nicht soft-gelöschten) Account per ID. */
    public Account getById(int id) {
        String sql = "SELECT * FROM account WHERE id = ? AND deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? map(rs) : null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Accounts", e);
        }
    }

    /** Liefert aktiven Account per primärer E-Mail (nicht soft-gelöscht). */
    public Account getByEmail(String email) {
        String sql = "SELECT * FROM account WHERE email = ? AND deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? map(rs) : null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Accounts", e);
        }
    }

    /** Liefert aktiven Account per E-Mail (auch soft-gelöscht). */
    public Account getByEmailIncludeDeleted(String email) {
        String sql = "SELECT * FROM account WHERE email = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? map(rs) : null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden des Accounts", e);
        }
    }

    /** Prüft ob eine E-Mail bereits als pending_email vergeben ist (aktive Accounts). */
    public boolean existsByPendingEmail(String email) {
        String sql = "SELECT 1 FROM account WHERE pending_email = ? AND deleted_at IS NULL LIMIT 1";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Prüfen der pending_email", e);
        }
    }

    public boolean existsByPendingEmail(String email, int excludedAccountId) {
        String sql = "SELECT 1 FROM account WHERE pending_email = ? AND id <> ? AND deleted_at IS NULL LIMIT 1";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setInt(2, excludedAccountId);
            ResultSet rs = ps.executeQuery();
            return rs.next();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Prüfen der pending_email", e);
        }
    }

    public List<Account> getAll() {
        String sql = "SELECT * FROM account WHERE deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            List<Account> list = new ArrayList<>();
            while (rs.next()) list.add(map(rs));
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Laden der Accounts", e);
        }
    }

    // ── Schreiben ───────────────────────────────────────────────────────────

    public void update(Account acc) {
        String sql = """
            UPDATE account
            SET first_name = ?,
                last_name = ?,
                email = ?,
                pending_email = ?,
                email_verified = ?,
                birthdate = ?
            WHERE id = ?
              AND deleted_at IS NULL
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, acc.getFirstName());
            ps.setString(2, acc.getLastName());
            ps.setString(3, acc.getEmail());
            ps.setString(4, acc.getPendingEmail());
            ps.setBoolean(5, acc.isEmailVerified());
            if (acc.getBirthdate() != null) {
                ps.setDate(6, Date.valueOf(acc.getBirthdate()));
            } else {
                ps.setNull(6, Types.DATE);
            }
            ps.setInt(7, acc.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Accounts", e);
        }
    }

    public void updatePassword(int id, String hashedPassword) {
        String sql = "UPDATE account SET pwd = ? WHERE id = ? AND deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, hashedPassword);
            ps.setInt(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Passworts", e);
        }
    }

    // ── Change-Email Flow ───────────────────────────────────────────────────

    /**
     * Setzt pending_email für den Account (Schritt 1 des Email-Änderungs-Flows).
     * Atomare Operation – vermeidet Race Conditions durch WHERE-Bedingung.
     */
    public void setPendingEmail(int accountId, String pendingEmail) {
        String sql = "UPDATE account SET pending_email = ? WHERE id = ? AND deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, pendingEmail);
            ps.setInt(2, accountId);
            ps.executeUpdate();
        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState())) {
                throw new BadRequestException("Diese E-Mail-Adresse ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Setzen der pending_email", e);
        }
    }

    /**
     * Schritt 2: pending_email → email übertragen und pending_email leeren.
     * Wird nach erfolgreicher Verifikation aufgerufen.
     * Atomare Operation in einer einzigen UPDATE-Anweisung.
     */
    public void confirmPendingEmail(int accountId) {
        String sql = """
            UPDATE account
            SET email = pending_email,
                pending_email = NULL,
                email_verified = true
            WHERE id = ?
              AND pending_email IS NOT NULL
              AND deleted_at IS NULL
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            int affected = ps.executeUpdate();
            if (affected == 0) {
                throw new BadRequestException("Keine ausstehende E-Mail-Änderung gefunden");
            }
        } catch (BadRequestException e) {
            throw e;
        } catch (SQLException e) {
            if ("23000".equals(e.getSQLState())) {
                throw new BadRequestException("Diese E-Mail-Adresse ist bereits vergeben");
            }
            throw new DatabaseException("Fehler beim Bestätigen der E-Mail-Änderung", e);
        }
    }

    public void clearPendingEmail(int accountId) {
        String sql = "UPDATE account SET pending_email = NULL WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen der pending_email", e);
        }
    }

    // ── Email-Verifikation ──────────────────────────────────────────────────

    public void setEmailVerified(int accountId) {
        String sql = "UPDATE account SET email_verified = true WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Verifizieren des Accounts", e);
        }
    }

    // ── Soft Delete ─────────────────────────────────────────────────────────

    /**
     * Loescht eine nicht-verifizierte Registrierung physisch.
     */
    public boolean deleteUnverifiedById(int id) {
        String sql = "DELETE FROM account WHERE id = ? AND email_verified = false AND deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Loeschen der nicht verifizierten Registrierung", e);
        }
    }

    /**
     * Soft-löscht einen Account (setzt deleted_at).
     * Historische Trips, Protocols und Vehicles bleiben erhalten
     * (dank RESTRICT / SET NULL auf den Foreign Keys).
     */
    public void softDelete(int id) {
        String sql = "UPDATE account SET deleted_at = NOW() WHERE id = ? AND deleted_at IS NULL";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen des Accounts", e);
        }
    }

    /** Löscht nicht-verifizierte Accounts älter als 24 h physisch (Cleanup-Job). */
    public void deleteUnverifiedOlderThan24Hours() {
        String sql = """
            DELETE FROM account
            WHERE email_verified = false
              AND created_at < NOW() - INTERVAL 24 HOUR
              AND deleted_at IS NULL
            """;
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Löschen nicht verifizierter Accounts", e);
        }
    }

    // ── Mapping ─────────────────────────────────────────────────────────────

    private Account map(ResultSet rs) throws SQLException {
        Account acc = new Account();
        acc.setId(rs.getInt("id"));
        acc.setFirstName(rs.getString("first_name"));
        acc.setLastName(rs.getString("last_name"));
        acc.setEmail(rs.getString("email"));
        acc.setPendingEmail(rs.getString("pending_email"));
        acc.setPassword(rs.getString("pwd"));
        acc.setEmailVerified(rs.getBoolean("email_verified"));
        Date date = rs.getDate("birthdate");
        if (date != null) acc.setBirthdate(date.toLocalDate());
        Timestamp deletedAt = rs.getTimestamp("deleted_at");
        if (deletedAt != null) acc.setDeletedAt(deletedAt.toLocalDateTime());
        return acc;
    }
}
