# TestManagedCpp

Reproducer for a CUDA issue with `extern __managed__` variables.

We have a managed variable, `__managed__ int m`, which needs to be accessed from
multiple files, so it is declared `extern` in a header and included from the
files which need to access it. One of these is a `.cpp` file.

Including `cuda_runtime.h` and adding the CUDA headers path to the C++ include
directories allows the `.cpp` file to compile. Enabling separable compilation
and position independent code allows the `.cu` file to compile.

However, this doesn't end up working correctly, in different ways on different
platforms. On Linux*, the program links fine, but when run produces incorrect
results:
```
>build$ ./TestManagedCpp 
m is -1
>build$ 
```
It is as if the `m` variable which was set to 42 (on the CPU, from the `.cpp`
file) is a different variable from the one set to -1 (also on the CPU, from the
`.cu` file).

Conversely, on Windows** the program fails to link; the `.cpp` file sees the
variable's true definition as `int m` whereas the `.cu` file sees it as `int
*m`.
```
2>testmanagedcpp.cpp.obj : error LNK2001: unresolved external symbol "int m" (?m@@3HA)
2>  Hint on symbols that are defined and could potentially match:
2>    "int * m" (?m@@3PEAHEA)
```

In terms of what is actually happening internally, it appears from
`<crt/host_defines.h>` that `extern __managed__ int m` is being converted to
`extern __attribute__((managed)) int m` on GCC or
`extern __declspec(managed) int m` on MSVC. I'm not sure how these are being
converted to something like `extern int *m` and `extern int m` respectively.

The [CUDA C Programming Guide](https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#managed-specifier)
does not mention anything about `__managed__` variables not being accessible
from within `.cpp` files. This reproducer does not violate any of the
restrictions listed there (except perhaps implicitly the restriction "The
address of a managed variable is not a constant expression", though the
reproducer never takes the address of the managed variable as in `int *foo = &m;`).

The Windows behavior of refusing to link is better than the Linux behavior of
incorrect output. But ideally this would actually work correctly, or if that's
not possible, a diagnostic like `accessing __managed__ variable within C/C++
file is not allowed` would be preferable to link errors.

\* Linux: Debian 4.19 x86_64, CUDA 11.5, driver 495.46, g++ 8.3 \
\*\* Windows: 10 x86_64, VS 2019, CUDA 11.6 \
Both: NVIDIA GeForce RTX 3080 \
Though I would be surprised if any of this was version specific.
