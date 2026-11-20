import { useEffect, useState, type DependencyList } from 'react'

// The state of a request to the backend (feat-9-walking-skeleton, Phase 300): the three phases that the user
// interface shows. The request starts when the component is shown and when a value of `deps` changes, and the
// answer of an old request is dropped (the flag `current`), so a late answer does not replace a new one.

export type Remote<T> =
  | { readonly phase: 'loading' }
  | { readonly phase: 'ready'; readonly value: T }
  | { readonly phase: 'failed'; readonly error: unknown }

export function useRemote<T>(load: () => Promise<T>, deps: DependencyList): Remote<T> {
  const [remote, setRemote] = useState<Remote<T>>({ phase: 'loading' })
  useEffect(() => {
    let current = true
    setRemote({ phase: 'loading' })
    load().then(
      (value) => {
        if (current) {
          setRemote({ phase: 'ready', value })
        }
      },
      (error: unknown) => {
        if (current) {
          setRemote({ phase: 'failed', error })
        }
      },
    )
    return () => {
      current = false
    }
    // The list of the dependencies is the one of the caller (the function `load` is new at each render).
  }, deps)
  return remote
}
