package com.ridepulse.backend.model; import jakarta.persistence.*; import lombok.AllArgsConstructor; import lombok.Data; import lombok.EqualsAndHashCode; import lombok.NoArgsConstructor; import java.util.UUID; /** * User Entity - Demonstrates INHERITANCE and POLYMORPHISM (OOP Concepts) * This is the parent class for different user types * Uses Table Per Class inheritance strategy */
@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = true)
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "dtype")
public class User extends BaseEntity {

    @Id
    @GeneratedValue
    @org.hibernate.annotations.UuidGenerator
    @Column(name = "user_id", updatable = false, nullable = false)
    private UUID userId;


    @Column(unique = true, nullable = false)
    private String email;

    @Column(unique = true)
    private String phone;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UserRole role;

    @Column(name = "is_active")
    private Boolean isActive = true;

    public boolean login(String password) {
        return this.passwordHash.equals(password);
    }

    public void logout() {
        System.out.println("User " + this.fullName + " logged out");
    }
}


