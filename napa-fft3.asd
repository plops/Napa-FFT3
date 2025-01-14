(asdf:defsystem "napa-fft3"
  :version "0.0.1"
  :licence "BSD"
  :description "Fast Fourier Transforms via generated split-radix"
  :serial t
  :components ((:file "package")
               (:file "support")

               (:file "bblock")
               (:file "gen-support")

               (:file "forward")
               (:file "inverse")
               (:file "bit-reversal")

               (:file "interface")
               (:file "easy-interface")
               (:file "windowing")
               (:file "real")

               (:file "test-support")
               (:file "tests")
               (:file "ergun-test")))
