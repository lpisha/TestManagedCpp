#include "testmanagedcpp.hpp"
#include <cstdio>

__managed__ int m;

__global__ void check_m_on_gpu(){
    printf("m is %d\n", m);
}

int main(){
    m = -1;
    set_m_to_42_in_cpp();
    cudaDeviceSynchronize();
    check_m_on_gpu<<<1,1>>>();
    cudaDeviceSynchronize();
}
