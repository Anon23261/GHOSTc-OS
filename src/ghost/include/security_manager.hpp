#pragma once

#include <string>
#include <vector>
#include <memory>
#include <openssl/ssl.h>
#include <openssl/evp.h>

namespace ghost {
namespace security {

class SecurityManager {
public:
    SecurityManager();
    ~SecurityManager();

    // Encryption
    std::vector<uint8_t> encrypt(const std::vector<uint8_t>& data, const std::string& key);
    std::vector<uint8_t> decrypt(const std::vector<uint8_t>& data, const std::string& key);
    
    // Key Management
    std::string generateKey(size_t length);
    void storeKey(const std::string& name, const std::string& key);
    std::string loadKey(const std::string& name);
    
    // System Protection
    void scanSystem();
    void monitorProcesses();
    void checkFileIntegrity();
    
    // Network Security
    void setupFirewall();
    void monitorConnections();
    void scanPorts();
    
    // Updates
    void checkForUpdates();
    void updateSystem();
    void updateSecurityRules();

private:
    // OpenSSL context
    SSL_CTX* ssl_ctx_;
    EVP_CIPHER_CTX* cipher_ctx_;
    
    // Security state
    struct SecurityState {
        bool firewall_active;
        bool monitoring_active;
        std::time_t last_scan;
        std::time_t last_update;
    };
    SecurityState state_;
    
    // Helper methods
    void initOpenSSL();
    void setupSecureStorage();
    void loadSecurityRules();
    void monitorSystemChanges();
};

} // namespace security
} // namespace ghost
