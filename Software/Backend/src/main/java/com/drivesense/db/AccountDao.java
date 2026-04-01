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
        String sql = "INSERT INTO account (fname, lname, pwd, email, birthdate) VALUES (?,?,?,?, ?)";
        try (Connection conn = dbConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1,acc.getfName());
            ps.setString(2,acc.getlName());
            ps.setString(3,acc.getPassword());
            ps.setString(4,acc.getEmail());
            if (acc.getBirthdate() != null) {
                ps.setDate(5, Date.valueOf(acc.getBirthdate()));
            } else {
                ps.setNull(5, Types.DATE);
            }

            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                acc.setId(rs.getInt(1));
            }
            return acc;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Accounts", e);
        }
    }

    public Account getById(int id) {
        String sql = "SELECT * FROM account WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Accounts", e);
        }
    }

    public Account getByEmail (String email) {
        String sql = "SELECT * FROM account WHERE email = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }

            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Accounts", e);
        }
    }

    public List<Account> getAll () {
        String sql = "SELECT * FROM account";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Account> accounts = new ArrayList<>();
            while (rs.next()) {
                accounts.add(map(rs));
            }
            return accounts;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Accounts", e);
        }
    }

    public void update(Account acc) {
        String sql = "UPDATE account SET fname = ?, lname = ?, email = ?, birthdate = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, acc.getfName());
            ps.setString(2, acc.getlName());
            ps.setString(3, acc.getEmail());
            if (acc.getBirthdate() != null) {
                ps.setDate(4, Date.valueOf(acc.getBirthdate()));
            } else {
                ps.setNull(4, Types.DATE);
            }
            ps.setInt(5, acc.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Accounts", e);
        }
    }

    public void updatePassword (int id, String password) {
        String sql = "UPDATE account SET pwd = ? WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
            PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1,password);
            ps.setInt(2,id);

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Passworts", e);
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM account WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim löschen des Accounts", e);
        }
    }

    private Account map(ResultSet rs) throws SQLException {
        Account acc = new Account();
        acc.setId(rs.getInt("id"));
        acc.setfName(rs.getString("fname"));
        acc.setlName(rs.getString("lname"));
        acc.setEmail(rs.getString("email"));
        acc.setPassword(rs.getString("pwd"));
        Date date = rs.getDate("birthdate");
        if (date != null) {
            acc.setBirthdate(date.toLocalDate());
        }
        return acc;
    }
}
