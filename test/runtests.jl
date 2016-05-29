using ChunkedArrays
using Base.Test

tic()
u = [2 2
     2 2]

chunkRand = ChunkedArray(randn,float(u),10)

println(next(chunkRand))

chunkRand2 = ChunkedArray(randn,(3,3),100)

println(next(chunkRand2))

chunkRand3 = ChunkedArray(randn,100)

println(next(chunkRand3))

u = [2;2;2;2]
chunkRand4 = ChunkedArray(randn,float(u),10)
println(next(chunkRand4))

println("Random Generating Benchmark")
const loopSize = 1000
const buffSize = 100
const numRuns = 400
Pkg.add("Benchmark")
using Benchmark

function test1()
  j=[0;0;0;0]
  for i = 1:loopSize
    j += randn(4)
  end
end

function test2()
  j=[0;0;0;0]
  chunks = 1000
  rands = randn(4,chunks)
  for k = 1:(loopSize÷chunks)
    rands[:] = randn(4,chunks)
    for i = 1:chunks
      j += rands[:,i]
    end
  end
end

function test3()
  j=[0;0;0;0]
  rands = randn(4,loopSize)
  for i = 1:loopSize
    j += rands[:,i]
  end
end

function test4()
  j=[0;0;0;0]
  chunks = 100
  rands = randn(4,chunks)
  for k = 1:(loopSize÷chunks)
    rands[:] = randn(4,chunks)
    for i = 1:chunks
      j += rands[:,i]
    end
  end
end

function test5()
  rands = randn(4,loopSize)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += rands[:,i]
  end
end

const savedRands = randn(4,loopSize)
function test6()
  j=[0;0;0;0]
  for i = 1:loopSize
    j += savedRands[:,i]
  end
end

const chunkRands = ChunkedArray(randn,(4,),loopSize)
function test7()
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(chunkRands)
  end
end

function test8()
  rands2 = ChunkedArray(randn,(4,),buffSize)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(rands2)
  end
end

function test9()
  rands3 = ChunkedArray(randn,(4,),loopSize)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += rands3.randBuffer[i]
  end
end

function test10()
  rands4 = ChunkedArray(randn,(4,),loopSize)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(rands4)
  end
end

function test11()
  rands2 = ChunkedArray(randn,(4,),buffSize,parallel=true)
  j=[0;0;0;0]
  for i = 1:loopSize
    j += next(rands2)
  end
end

t1 = benchmark(test1,"Test 1",numRuns)[:AverageWall][1]
t2 = benchmark(test2,"Test 2",numRuns)[:AverageWall][1]
t3 = benchmark(test3,"Test 3",numRuns)[:AverageWall][1]
t4 = benchmark(test4,"Test 4",numRuns)[:AverageWall][1]
t5 = benchmark(test5,"Test 5",numRuns)[:AverageWall][1]
t6 = benchmark(test6,"Test 6",numRuns)[:AverageWall][1]
t7 = benchmark(test7,"Test 7",numRuns)[:AverageWall][1]
t8 = benchmark(test8,"Test 8",numRuns)[:AverageWall][1]
t9 = benchmark(test9,"Test 9",numRuns)[:AverageWall][1]
t10= benchmark(test10,"Test 10",numRuns)[:AverageWall][1]
t11= benchmark(test10,"Test 11",numRuns)[:AverageWall][1]

println("""Test Results For Average Time:
One-by-one:                             $t1
Thousand-by-Thousand:                   $t2
Altogether:                             $t3
Hundred-by-hundred:                     $t4
Take at Beginning:                      $t5
Pre-made Rands:                         $t6
Chunked Rands Premade:                  $t7
Chunked Rands 1000 buffer:              $t8
Chunked Rands Direct:                   $t9
Chunked Rands Max buffer:               $t10
Parallel Chunked Rands 1000 buffer:     $t11
""")
toc()
