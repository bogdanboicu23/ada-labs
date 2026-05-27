#include <mpi.h>
#include "sha256.h"
#include <iostream>
#include <cstdint>
#include <chrono>
#include <cstring>

int check_commandline_passed_arguments(int argc, char *argv[])
{
    char* app_name = argv[0];
    if (argc == 1) {
        std::cout << "Call application " << app_name << " with arguments [n]." << std::endl;
        std::cout << "Example:" << std::endl;
        std::cout << app_name << " 7 -- Application will try to solve crypto puzzle SHA256 with nonce that will generate 7 leading 0s of the hashed message." << std::endl;
        std::cout << app_name << " 8 -- Application will try to solve crypto puzzle SHA256 with nonce that will generate 8 leading 0s of the hashed message." << std::endl;
        exit(0);
    }
    if (argc > 2) {
        std::cout << "Incorrect arguments passed." << std::endl;
        std::cout << "Call application " << app_name << " for help message" << std::endl;
        exit(1);
    }
    return 0;
}

int main(int argc, char *argv[])
{
    check_commandline_passed_arguments(argc, argv);

    MPI_Init(&argc, &argv);

    int world_size, world_rank;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);

    int difficulty = atoi(argv[1]);
    const std::string message("Hello World");
    std::string nonce_needle(difficulty, '0');

    if (world_rank == 0) {
        SHA256 sha256;
        std::cout << "Message: " << message << std::endl;
        std::cout << "Hash: " << sha256(message) << std::endl;
        std::cout << "Looking for nonce with difficulty " << difficulty << "..." << std::endl;
        std::cout << "Running on " << world_size << " processes" << std::endl;
    }

    std::cout << "Hello from processor " << processor_name
              << ", rank " << world_rank
              << " out of " << world_size << std::endl;

    // Barrier so all processes start timing together
    MPI_Barrier(MPI_COMM_WORLD);
    auto t1 = std::chrono::high_resolution_clock::now();

    SHA256 localSha256;
    char solution_buf[256] = {0};
    bool found = false;

    for (uint64_t i = world_rank; i < UINT64_MAX && !found; i += world_size)
    {
        std::string solution_candidate = message + std::to_string(i);
        std::string hash_code = localSha256(solution_candidate);

        if (hash_code.compare(0, difficulty, nonce_needle) == 0)
        {
            found = true;
            std::cout << "Process " << world_rank
                      << " found solution: " << solution_candidate
                      << " -> " << hash_code << std::endl;
            // FIX: copy with null terminator guaranteed
            strncpy(solution_buf, solution_candidate.c_str(), 255);
            solution_buf[255] = '\0';
            break;
        }

        // Periodically check if any other process has found a solution
        if (i % 100000 == (uint64_t)world_rank)
        {
            int found_flag = found ? 1 : 0;
            int global_found = 0;
            MPI_Allreduce(&found_flag, &global_found, 1, MPI_INT, MPI_MAX, MPI_COMM_WORLD);
            if (global_found) break;
        }
    }

    // Final reduce to confirm globally
    int found_flag = found ? 1 : 0;
    int global_found = 0;
    MPI_Allreduce(&found_flag, &global_found, 1, MPI_INT, MPI_MAX, MPI_COMM_WORLD);

  
    int finder_rank = -1;
    if (found) finder_rank = world_rank;

    int global_finder = -1;
    MPI_Allreduce(&finder_rank, &global_finder, 1, MPI_INT, MPI_MAX, MPI_COMM_WORLD);

    // All processes call Bcast with the same root
    if (global_found && global_finder >= 0)
    {
        MPI_Bcast(solution_buf, 256, MPI_CHAR, global_finder, MPI_COMM_WORLD);
    }

    auto t2 = std::chrono::high_resolution_clock::now();
    auto duration_milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);

    if (world_rank == 0)
    {
        if (global_found)
        {
            SHA256 sha256_final;
            std::string solution(solution_buf);
            std::cout << "\nSolution: " << solution << std::endl;
            std::cout << "Hash:     " << sha256_final(solution) << std::endl;
        }
        else
        {
            std::cout << "No solution found." << std::endl;
        }
        std::cout << "Time: " << duration_milliseconds.count() << " milliseconds" << std::endl;
    }
    std::cout << "Time: " << duration_milliseconds.count() << " milliseconds" << std::endl;

    MPI_Finalize();
    return 0;
}