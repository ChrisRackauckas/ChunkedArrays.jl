__precompile__()

module ChunkedArrays
  using EllipsisNotation

  const BUFFER_SIZE_DEFAULT = 1000
  const PARALLEL_DEFAULT = false

  import Base: start, next, done, getindex

  type ChunkedArray{F,T,N,O}
    chunkfunc::F
    outputSize::O
    bufferSize::Int
    state::Int
    randBuffer::Vector{T}
  end

  output_size{F,T,N,O}(c::ChunkedArray{F,T,N,O}) = N

  function Base.next(bufRand::ChunkedArray)
    if bufRand.state>=bufRand.bufferSize
      if output_size(bufRand) == 0
        bufRand.randBuffer[:] = bufRand.chunkfunc(bufRand.bufferSize)
      else
        bufRand.randBuffer[:] = [bufRand.chunkfunc(bufRand.outputSize...) for i=1:bufRand.bufferSize]
      end
      bufRand.state = 0
    end
    bufRand.state += 1
    bufRand.randBuffer[bufRand.state]
  end

  function ChunkedArray(chunkfunc::Function,bufferSize::Int=BUFFER_SIZE_DEFAULT,T::Type=Float64)
    ChunkedArray{typeof(chunkfunc),T,0,Tuple{}}(
                 chunkfunc,(),bufferSize,0,chunkfunc(bufferSize))
  end

  function ChunkedArray(chunkfunc,randPrototype::AbstractArray,bufferSize=BUFFER_SIZE_DEFAULT)
    outputSize = size(randPrototype)
    ChunkedArray{typeof(chunkfunc),typeof(randPrototype),
                 length(outputSize),typeof(outputSize)}(
                 chunkfunc,outputSize,bufferSize,0,
                 [chunkfunc(outputSize...) for i=1:bufferSize])
  end

  export ChunkedArray

end # module
