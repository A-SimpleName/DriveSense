package com.drivesense.db;

import com.drivesense.DbConnection;
import com.drivesense.exceptions.DatabaseException;
import com.drivesense.model.Protocol;
import com.drivesense.model.UserGroup;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Repository
public class ProtocolDao {

    @Autowired
    private DbConnection dbConnection;

    public Protocol insert(Protocol protocol) {
        String sql = "INSERT INTO protocol (created_by_profile_id, usergroup_id,name) VALUES (?,?,?)";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setInt(1,protocol.getCreatedByProfileId());
            ps.setInt(2,protocol.getUsergroupId());
            ps.setString(3,protocol.getName());


            ps.executeUpdate();

            ResultSet rs = ps.getGeneratedKeys();
            if (rs.next()) {
                protocol.setId(rs.getInt(1));
                return protocol;
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim speichern des Protokolls", e);
        }
    }

    public List<Protocol> getByProfileId(int createdByProfileId) {
        String sql = "SELECT * FROM protocol WHERE created_by_profile_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, createdByProfileId);
            ResultSet rs = ps.executeQuery();

            List<Protocol> protocols = new ArrayList<>();
            while (rs.next()) {
                protocols.add(map(rs));
            }
            return protocols;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Protokolls", e);
        }
    }

    public Protocol getById(int id) {
        String sql = "SELECT * FROM protocol WHERE id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                return map(rs);
            }
            return null;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Protokolls", e);
        }
    }

    public List<Protocol> getByGroup(int usergroupId) {
        String sql = "SELECT * FROM protocol WHERE usergroup_id = ?";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setInt(1, usergroupId);
            ResultSet rs = ps.executeQuery();

            List<Protocol> protocols = new ArrayList<>();
            while (rs.next()) {
                protocols.add(map(rs));
            }
            return protocols;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden des Protokolls", e);
        }
    }

    public List<Protocol> getAll () {
        String sql = "SELECT * FROM protocol";

        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            List<Protocol> protocols = new ArrayList<>();
            while (rs.next()) {
                protocols.add(map(rs));
            }
            return protocols;

        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim laden der Protokolle", e);
        }
    }

    public void update(Protocol protocol) {
        String sql = "UPDATE protocol SET name = ? WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, protocol.getName());
            ps.setInt(2,protocol.getId());

            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim Aktualisieren des Protokolls", e);
        }
    }

    public void deleteById(int id) {
        String sql = "DELETE FROM protocol WHERE id = ?";
        try (Connection conn = dbConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1,id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new DatabaseException("Fehler beim löschen des Protokolls", e);
        }
    }

    private Protocol map(ResultSet rs) throws SQLException {
        Protocol protocol = new Protocol();
        protocol.setId(rs.getInt("id"));
        protocol.setCreatedByProfileId(rs.getInt("created_by_profile_id"));
        protocol.setUsergroupId(rs.getInt("usergroup_id"));
        protocol.setName(rs.getString("name"));
        return protocol;
    }
}
