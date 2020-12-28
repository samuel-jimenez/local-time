(local-time:enable-local-time-syntax)
(in-package #:local-time.test)

(defsuite* (reader :in test))


(deftest test/reader/reader ()
		(is (timestamp=
			#@2001-01-01T00:00:00.000000Z
			(parse-timestring "2001-01-01T00:00:00.000000Z"))))
