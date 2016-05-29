__precompile__()

module ChunkedArrays
  using Compat
  import Base.getindex, Base.setindex!
  const .. = Val{:...}
  const BUFFER_SIZE_DEFAULT = 1000
  const PARALLEL_DEFAULT = false
  getindex{T}(A::AbstractArray{T,1}, ::Type{Val{:...}}, n::Int) = A[n]
  getindex{T}(A::AbstractArray{T,2}, ::Type{Val{:...}}, n::Int) = A[ :, n]
  getindex{T}(A::AbstractArray{T,3}, ::Type{Val{:...}}, n::Int) = A[ :, :, n]
  getindex{T}(A::AbstractArray{T,4}, ::Type{Val{:...}}, n::Int) = A[ :, :, :, n]
  getindex{T}(A::AbstractArray{T,5}, ::Type{Val{:...}}, n::Int) = A[ :, :, :, :, n]

  import Base: start, next, done, getindex

  if VERSION > v"0.4.5"
    type ChunkedArray{T,N1,N2}
      chunkfunc::Function
      outputSize::NTuple{N1,Int}
      bufferSize::Int
      state::Int
      randBuffer::Array{T,N2}
      parallel::Bool
      randBuffer2::Future
    end
  else
    type ChunkedArray{T,N1,N2}
      chunkfunc::Function
      outputSize::NTuple{N1,Int}
      bufferSize::Int
      state::Int
      randBuffer::Array{T,N2}
      parallel::Bool
      randBuffer2::RemoteRef{Channel{Any}}
    end
  end

  function Base.next(bufRand::ChunkedArray)
    if bufRand.state>=bufRand.bufferSize
      if bufRand.parallel
        if bufRand.outputSize == ()
          bufRand.randBuffer2 = @spawn bufRand.chunkfunc(bufRand.bufferSize)
        elseif length(bufRand.outputSize) == 1
          bufRand.randBuffer2 = @spawn bufRand.chunkfunc(bufRand.outputSize[1],bufRand.bufferSize)
        else
          bufRand.randBuffer2 = @spawn bufRand.chunkfunc(bufRand.outputSize...,bufRand.bufferSize)
        end
        @compat bufRand.randBuffer[:] = fetch(bufRand.randBuffer2)[:]
      else
        if bufRand.outputSize == ()
          bufRand.randBuffer[:] = bufRand.chunkfunc(bufRand.bufferSize)
        elseif length(bufRand.outputSize) == 1
          bufRand.randBuffer[:] = bufRand.chunkfunc(bufRand.outputSize[1],bufRand.bufferSize)
        else
          bufRand.randBuffer[:] = bufRand.chunkfunc(bufRand.outputSize...,bufRand.bufferSize)
        end
      end
      bufRand.state = 0
    end
    bufRand.state += 1
    if length(bufRand.outputSize)<2
      return(bufRand.randBuffer[bufRand.state])
    else
      return(bufRand.randBuffer[..,bufRand.state])
    end
  end

  function ChunkedArray(chunkfunc::Function,outputSize::NTuple,bufferSize::Int=BUFFER_SIZE_DEFAULT,T::Type=Float64;parallel=PARALLEL_DEFAULT)
    if parallel
      ChunkedArray{T,length(outputSize),length(outputSize)+1}(chunkfunc,outputSize,bufferSize,0,chunkfunc(outputSize...,bufferSize),parallel,@spawn chunkfunc(outputSize...,bufferSize))
    else
      @compat ChunkedArray{T,length(outputSize),length(outputSize)+1}(chunkfunc,outputSize,bufferSize,0,chunkfunc(outputSize...,bufferSize),parallel,RemoteChannel())
    end
  end


  function ChunkedArray(chunkfunc::Function,bufferSize::Int=BUFFER_SIZE_DEFAULT,T::Type=Float64;parallel=PARALLEL_DEFAULT)
    if parallel
      ChunkedArray{T,0,1}(chunkfunc,(),bufferSize,0,chunkfunc(bufferSize),parallel,@spawn chunkfunc(bufferSize))
    else
      @compat ChunkedArray{T,0,1}(chunkfunc,(),bufferSize,0,chunkfunc(bufferSize),parallel,RemoteChannel())
    end
  end

  function ChunkedArray(chunkfunc,randPrototype::AbstractArray,bufferSize=BUFFER_SIZE_DEFAULT;parallel=PARALLEL_DEFAULT)
    outputSize = size(randPrototype)
    if parallel
      ChunkedArray{eltype(randPrototype),length(outputSize),length(outputSize)+1}(chunkfunc,outputSize,bufferSize,0,
      chunkfunc(outputSize...,bufferSize),parallel,@spawn chunkfunc(outputSize...,bufferSize))
    else
      @compat ChunkedArray{eltype(randPrototype),length(outputSize),length(outputSize)+1}(chunkfunc,outputSize,bufferSize,0,
      chunkfunc(outputSize...,bufferSize),parallel,RemoteChannel())
    end
  end

  export ChunkedArray

end # module
