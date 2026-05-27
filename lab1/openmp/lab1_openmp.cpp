#include <omp.h>
#include <iostream> 
#include <cstdint>
#include <chrono>
#include "sha256.h"

int check_comandline_passed_arguments(int argc, char *argv[])
{
    char* app_name = argv[0];
    std::cout << "Count of arguments passed: " << argc << std::endl;
    if(argc == 1){
        std::cout << "Call application "<< app_name << " with arguments [n]." << std::endl;
        std::cout << "Example:" << std::endl;
        std::cout << app_name <<" 7 -- Application will try to solve crypto puzzle SHA256 with nonce that will generate 7 trailing 0 of the hashed message." << std::endl;
        std::cout << app_name <<" 8 -- Application will try to solve crypto puzzle SHA256 with nonce that will generate 8 trailing 0 of the hashed message." << std::endl;
        exit(0);
    }
    if(argc > 2)
    {
        std::cout << "Incorrect arguments passed." << std::endl;
        std::cout << "Call application "<< app_name << " for help message" << std::endl;
        exit(1);
    }
    return 0;
}

int main(int argc, char *argv[])
{
    check_comandline_passed_arguments(argc, argv);

    int difficulty = atoi(argv[1]);
    SHA256 sha256;
    const std::string message("Hello World");
    std::string nonce_needle(difficulty, '0');

    std::cout << "Message:" << std::endl << message << std::endl;
    std::cout << "Hash:" << std::endl << sha256(message) << std::endl;
    std::cout << std::endl << std::endl;
    std::cout << "Looking for nonce to solve crypto-puzzle with " << difficulty << " difficulty..." << std::endl;
    std::cout << "Application with OpenMP parameters:" << std::endl;

    std::chrono::high_resolution_clock::time_point t1 = std::chrono::high_resolution_clock::now();

    std::string global_solution = "";
    bool found = false;

    #pragma omp parallel num_threads(32) shared(found, global_solution)
    {
        int current_thread_id = omp_get_thread_num();
        int total_threads = omp_get_num_threads();

        std::cout << "Total threads: " << total_threads << ", Current thread: " << current_thread_id << std::endl;

        SHA256 local_sha256;

        for(uint64_t i = current_thread_id; i < UINT64_MAX && !found; i += total_threads)
        {
            std::string solution_candidate = message + std::to_string(i);
            std::string hash_code = local_sha256(solution_candidate);

            if(hash_code.compare(0, difficulty, nonce_needle) == 0)
            {
                #pragma omp critical
                {
                    if(!found)
                    {
                        std::cout << "Thread " << current_thread_id << " found a solution: " << solution_candidate << std::endl;
                        found = true;
                        global_solution = solution_candidate;
                    }
                }
                break;
            }
        }
    }

    std::chrono::high_resolution_clock::time_point t2 = std::chrono::high_resolution_clock::now();
    std::chrono::milliseconds duration_milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(t2 - t1);

    if(found)
    {
        SHA256 sha256_final;
        std::cout << "Solution: " << std::endl << global_solution << std::endl;
        std::cout << "Hash:" << std::endl << sha256_final(global_solution) << std::endl;
    }
    else
    {
        std::cout << "No solution found." << std::endl;
    }

    std::cout << duration_milliseconds.count() << " milliseconds\n";

    return 0;
}