#pragma once

#include <string>
#include <vector>
#include <memory>
#include <sqlite3.h>
#include <chrono>

namespace ghost {

class Memory {
public:
    Memory();
    ~Memory();

    struct Experience {
        std::string event;
        std::chrono::system_clock::time_point timestamp;
        float emotional_impact;
        float importance;
        std::vector<std::string> tags;
    };

    // Memory operations
    void storeExperience(const Experience& exp);
    std::vector<Experience> recall(const std::string& query);
    void strengthen(const std::string& event_id);
    void forget(const std::string& event_id);

    // Memory consolidation
    void consolidate();
    void prune();
    
    // Memory analysis
    float getRelevance(const std::string& memory, const std::string& context);
    std::vector<std::string> findPatterns();

private:
    // Database connection
    std::unique_ptr<sqlite3, void(*)(sqlite3*)> db_;
    
    // Memory organization
    struct MemoryCluster {
        std::vector<std::string> related_memories;
        float average_importance;
        std::chrono::system_clock::time_point last_access;
    };
    std::vector<MemoryCluster> memory_clusters_;

    // Memory indexing
    struct MemoryIndex {
        std::string keyword;
        std::vector<std::string> memory_ids;
        float relevance_score;
    };
    std::vector<MemoryIndex> memory_index_;

    // Helper methods
    void initDatabase();
    void createTables();
    void updateIndices();
    void cleanupOldMemories();
    float calculateMemoryStrength(const Experience& exp);
};

} // namespace ghost
