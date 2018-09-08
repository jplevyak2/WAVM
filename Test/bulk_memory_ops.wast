;; passive data segments and data segment encoding

(assert_invalid
	(module (data passive "test"))
	"data segment without memory"
)
(assert_invalid
	(module (memory $m 1) (data passive (i32.const 0) "test"))
	"unexpected expression"
)

(module binary
    "\00asm" "\01\00\00\00"              ;; WebAssembly version 1
    "\05\03\01"                          ;; memory section: 3 bytes, 1 entry
    "\00\01"                             ;;   (memory 1)
	"\0b\07\01"                          ;; data section: 5 bytes, 1 entry
	"\00"                                ;;   [0] active data segment, memory 0
	"\41\00\0b"                          ;;     base offset (i32.const 0)
	"\01\00"                             ;;     1 byte of data
)

(module binary
    "\00asm" "\01\00\00\00"              ;; WebAssembly version 1
    "\05\03\01"                          ;; memory section: 3 bytes, 1 entry
    "\00\01"                             ;;   (memory 1)
	"\0c\02\01"                          ;; data declaration section: 2 bytes, 1 entry
	"\01"                                ;;   [0] passive data segment
	"\0b\03\01"                          ;; data section: 3 bytes, 1 entry
	"\01\00"                             ;;   [0] passive data segment: 1 byte of data
)

(module binary
    "\00asm" "\01\00\00\00"              ;; WebAssembly version 1
    "\05\03\01"                          ;; memory section: 3 bytes, 1 entry
    "\00\01"                             ;;   (memory 1)
	"\0c\03\02"                          ;; data declaration section: 3 bytes, 2 entries
	"\00"                                ;;   [0] active data segment
	"\01"                                ;;   [1] passive data segment
	"\0b\09\02"                          ;; data section: 9 bytes, 2 entries
	"\00"                                ;;   [0] active data segment, memory 0
	"\41\00\0b"                          ;;     base offset (i32.const 0)
	"\01\00"                             ;;     1 byte of data
	"\01\00"                             ;;   [1] passive data segment: 1 byte of data
)

(assert_malformed
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1
		"\05\03\01"                          ;; memory section: 3 bytes, 1 entry
		"\00\01"                             ;;   (memory 1)
		"\0c\03\02"                          ;; data declaration section: 3 bytes, 2 entries
		"\00"                                ;;   [0] active data segment
		"\01"                                ;;   [1] passive data segment
		"\0b\07\01"                          ;; data section: 7 bytes, 1 entries
		"\00"                                ;;   [0] active data segment, memory 0
		"\41\00\0b"                          ;;     base offset (i32.const 0)
		"\01\00"                             ;;     1 byte of data
	)
	"data section contains a different number of data segments than were declared in the data declaration section"
)

(assert_malformed
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1
		"\05\03\01"                          ;; memory section: 3 bytes, 1 entry
		"\00\01"                             ;;   (memory 1)
		"\0c\03\02"                          ;; data declaration section: 3 bytes, 2 entries
		"\00"                                ;;   [0] active data segment
		"\01"                                ;;   [1] passive data segment
	)
	"module contained data declaration section, but no corresponding data section"
)

;; memory.init/memory.drop

(assert_invalid
	(module
		(memory $m 1)
		(data passive "test")
		(func (memory.init (i32.const 0) (i32.const 0) (i32.const 0)))
	)
	"invalid data segment index"
)
(assert_invalid
	(module
		(memory $m 1)
		(data passive "test")
		(func (memory.init 1 (i32.const 0) (i32.const 0) (i32.const 0)))
	)
	"invalid data segment index"
)
(assert_invalid
	(module
		(memory $m 1)
		(data passive "test")
		(func (memory.init 0 1 (i32.const 0) (i32.const 0) (i32.const 0)))
	)
	"invalid memory index"
)
(assert_invalid
	(module
		(memory $m 1)
		(data passive "test")
		(func (memory.drop 1))
	)
	"invalid data segment index"
)

(assert_invalid
	(module
		(memory $m 1)
		(data (i32.const 0) "test")
		(func (memory.init 0 (i32.const 0) (i32.const 0) (i32.const 0)))
	)
	"memory.init may not reference an active data segment"
)
(assert_invalid
	(module
		(memory $m 1)
		(data (i32.const 0) "test")
		(func (memory.drop 0))
	)
	"memory.drop may not reference an active data segment"
)

(module
	(memory $m 1 1)
	(data passive "a")
	(func (memory.init 0 (i32.const 0) (i32.const 0) (i32.const 0)))
)

(module
	(memory $m 1 1)
	(data passive "a")
	(func (memory.init 0 0 (i32.const 0) (i32.const 0) (i32.const 0)))
)

(module
	(memory $m 1 1)
	(data passive "a")
	(func (memory.init 0 $m (i32.const 0) (i32.const 0) (i32.const 0)))
)

(module binary
	"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

	"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
	"\60\00\00"                          ;;   Function type () -> ()

	"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
	"\00"                                ;;   Function 0: type 0

	"\05\03\01"                          ;; memory section: 3 bytes, 1 entry
	"\00\01"                             ;;   (memory 1)
	
	"\0c\02\01"                          ;; data declaration section: 2 bytes, 1 entry
	"\01"                                ;;   [0] passive data segment

	"\0a\11\01"                          ;; Code section
	"\0f\00"                             ;; function 0: 15 bytes, 0 local sets
	"\41\00"                             ;; i32.const 0
	"\41\00"                             ;; i32.const 0
	"\41\00"                             ;; i32.const 0
	"\fc\08\00\00"                       ;; memory.init 0 0
	"\fc\09\00"                          ;; memory.drop 0
	"\0b"                                ;; end

	"\0b\03\01"                          ;; data section: 3 bytes, 1 entry
	"\01\00"                             ;;   [0] 1 byte passive data segment
)

(assert_invalid
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

		"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
		"\60\00\00"                          ;;   Function type () -> ()

		"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
		"\00"                                ;;   Function 0: type 0

		"\05\03\01"                          ;; memory section: 3 bytes, 1 entry
		"\00\01"                             ;;   (memory 1)
		
		"\0c\02\01"                          ;; data declaration section: 2 bytes, 1 entry
		"\01"                                ;;   [0] passive data segment

		"\0a\11\01"                          ;; Code section
		"\0f\00"                             ;; function 0: 15 bytes, 0 local sets
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\fc\08\01\00"                       ;; memory.init 1 0
		"\fc\09\01"                          ;; memory.drop 1
		"\0b"                                ;; end
		
		"\0b\03\01"                          ;; data section: 3 bytes, 1 entry
		"\01\00"                             ;;   [0] 1 byte passive data segment
	)
	"invalid data segment index"
)

(assert_invalid
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

		"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
		"\60\00\00"                          ;;   Function type () -> ()

		"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
		"\00"                                ;;   Function 0: type 0

		"\05\03\01"                          ;; memory section: 3 bytes, 1 entry
		"\00\01"                             ;;   (memory 1)

		"\0a\11\01"                          ;; Code section
		"\0f\00"                             ;; function 0: 15 bytes, 0 local sets
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\fc\08\00\01"                       ;; memory.init 0 1
		"\fc\09\00"                          ;; memory.drop 0
		"\0b"                                ;; end

		"\0b\04\01"                          ;; data section: 5 bytes, 1 entry
		"\01"                                ;; passive data segment
		"\01\00"                             ;;   1 byte of data
	)
	"invalid memory index"
)

(assert_invalid
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

		"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
		"\60\00\00"                          ;;   Function type () -> ()

		"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
		"\00"                                ;;   Function 0: type 0

		"\05\03\01"                          ;; memory section: 3 bytes, 1 entry
		"\00\01"                             ;;   (memory 1)

		"\0a\11\01"                          ;; Code section
		"\0f\00"                             ;; function 0: 15 bytes, 0 local sets
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\fc\08\00\00"                       ;; memory.init 0 0
		"\fc\09\00"                          ;; memory.drop 0
		"\0b"                                ;; end
		
		"\0b\07\01"                          ;; data section: 5 bytes, 1 entry
		"\00\41\00\0b"                       ;; active data segment, base offset (i32.const 0)
		"\01\00"                             ;;   1 byte of data
	)
	"can't use active data segment in memory.init"
)

(module
	(memory $m 1 1)

	(data passive "\01\02\03\04")
	(data passive "\05\06\07\08\09\0a\0b\0c\0d\0e\0f\10\11\12\13\14")

	(func (export "memory.init 0")
		(param $destAddress i32)
		(param $sourceOffset i32)
		(param $numBytes i32)
		(memory.init 0 $m (get_local $destAddress) (get_local $sourceOffset) (get_local $numBytes))
	)
	
	(func (export "memory.init 1")
		(param $destAddress i32)
		(param $sourceOffset i32)
		(param $numBytes i32)
		(memory.init 1 $m (get_local $destAddress) (get_local $sourceOffset) (get_local $numBytes))
	)
	
	(func (export "memory.drop 0") (memory.drop 0))
	(func (export "memory.drop 1") (memory.drop 1))

	(func (export "i32.load8_u") (param $address i32) (result i32)
		(i32.load8_u (get_local $address))
	)
)

(assert_return (invoke "memory.init 0" (i32.const 0) (i32.const 0) (i32.const 4)))
(assert_return (invoke "i32.load8_u" (i32.const 0)) (i32.const 0x1))
(assert_return (invoke "i32.load8_u" (i32.const 1)) (i32.const 0x2))
(assert_return (invoke "i32.load8_u" (i32.const 2)) (i32.const 0x3))
(assert_return (invoke "i32.load8_u" (i32.const 3)) (i32.const 0x4))
(assert_return (invoke "i32.load8_u" (i32.const 4)) (i32.const 0))

(assert_return (invoke "memory.init 1" (i32.const 0) (i32.const 0) (i32.const 16)))
(assert_return (invoke "i32.load8_u" (i32.const 0 )) (i32.const 0x05))
(assert_return (invoke "i32.load8_u" (i32.const 1 )) (i32.const 0x06))
(assert_return (invoke "i32.load8_u" (i32.const 2 )) (i32.const 0x07))
(assert_return (invoke "i32.load8_u" (i32.const 3 )) (i32.const 0x08))
(assert_return (invoke "i32.load8_u" (i32.const 4 )) (i32.const 0x09))
(assert_return (invoke "i32.load8_u" (i32.const 5 )) (i32.const 0x0a))
(assert_return (invoke "i32.load8_u" (i32.const 6 )) (i32.const 0x0b))
(assert_return (invoke "i32.load8_u" (i32.const 7 )) (i32.const 0x0c))
(assert_return (invoke "i32.load8_u" (i32.const 8 )) (i32.const 0x0d))
(assert_return (invoke "i32.load8_u" (i32.const 9 )) (i32.const 0x0e))
(assert_return (invoke "i32.load8_u" (i32.const 10)) (i32.const 0x0f))
(assert_return (invoke "i32.load8_u" (i32.const 11)) (i32.const 0x10))
(assert_return (invoke "i32.load8_u" (i32.const 12)) (i32.const 0x11))
(assert_return (invoke "i32.load8_u" (i32.const 13)) (i32.const 0x12))
(assert_return (invoke "i32.load8_u" (i32.const 14)) (i32.const 0x13))
(assert_return (invoke "i32.load8_u" (i32.const 15)) (i32.const 0x14))

(assert_return (invoke "memory.init 0" (i32.const 1) (i32.const 0) (i32.const 2)))
(assert_return (invoke "i32.load8_u" (i32.const 0)) (i32.const 0x5))
(assert_return (invoke "i32.load8_u" (i32.const 1)) (i32.const 0x1))
(assert_return (invoke "i32.load8_u" (i32.const 2)) (i32.const 0x2))
(assert_return (invoke "i32.load8_u" (i32.const 3)) (i32.const 0x8))

(assert_return (invoke "memory.init 0" (i32.const 10) (i32.const 1) (i32.const 3)))
(assert_return (invoke "i32.load8_u" (i32.const 9)) (i32.const 0xe))
(assert_return (invoke "i32.load8_u" (i32.const 10)) (i32.const 0x2))
(assert_return (invoke "i32.load8_u" (i32.const 11)) (i32.const 0x3))
(assert_return (invoke "i32.load8_u" (i32.const 12)) (i32.const 0x4))
(assert_return (invoke "i32.load8_u" (i32.const 13)) (i32.const 0x12))

(assert_return (invoke "memory.init 0" (i32.const 65532) (i32.const 0) (i32.const 4)))
(assert_trap (invoke "memory.init 0" (i32.const 65532) (i32.const 4) (i32.const 1)) "out of bounds memory access")
(assert_trap (invoke "memory.init 0" (i32.const 65533) (i32.const 0) (i32.const 4)) "out of bounds memory access")
(assert_return (invoke "memory.init 1" (i32.const 65520) (i32.const 0) (i32.const 16)))
(assert_trap (invoke "memory.init 1" (i32.const 65541) (i32.const 0) (i32.const 16)) "out of bounds memory access")
(assert_trap (invoke "memory.init 1" (i32.const 65520) (i32.const 1) (i32.const 16)) "out of bounds memory access")

(assert_trap (invoke "memory.init 0" (i32.const 0xffffffff) (i32.const 0) (i32.const 1)) "out of bounds memory access")
(assert_trap (invoke "memory.init 0" (i32.const 0) (i32.const 0xffffffff) (i32.const 1)) "out of bounds memory access")

(assert_return (invoke "memory.drop 0"))
(assert_trap (invoke "memory.init 0" (i32.const 0) (i32.const 0) (i32.const 4)) "invalid argument")
(assert_trap (invoke "memory.drop 0") "invalid argument")

(module
	(memory $m 1 1)

	(data (i32.const 0) "\10\11\12\13\14\15\16\17")
	
	(func (export "memory.copy")
		(param $destAddress i32)
		(param $sourceAddress i32)
		(param $numBytes i32)
		(memory.copy (get_local $destAddress) (get_local $sourceAddress) (get_local $numBytes))
	)
	
	(func (export "i32.load8_u") (param $address i32) (result i32)
		(i32.load8_u (get_local $address))
	)
)

(assert_return (invoke "i32.load8_u" (i32.const 0)) (i32.const 0x10))
(assert_return (invoke "i32.load8_u" (i32.const 1)) (i32.const 0x11))
(assert_return (invoke "i32.load8_u" (i32.const 2)) (i32.const 0x12))
(assert_return (invoke "i32.load8_u" (i32.const 3)) (i32.const 0x13))
(assert_return (invoke "i32.load8_u" (i32.const 4)) (i32.const 0x14))
(assert_return (invoke "i32.load8_u" (i32.const 5)) (i32.const 0x15))
(assert_return (invoke "i32.load8_u" (i32.const 6)) (i32.const 0x16))
(assert_return (invoke "i32.load8_u" (i32.const 7)) (i32.const 0x17))

(assert_return (invoke "memory.copy" (i32.const 8) (i32.const 0) (i32.const 8)))
(assert_return (invoke "i32.load8_u" (i32.const 8 )) (i32.const 0x10))
(assert_return (invoke "i32.load8_u" (i32.const 9 )) (i32.const 0x11))
(assert_return (invoke "i32.load8_u" (i32.const 10)) (i32.const 0x12))
(assert_return (invoke "i32.load8_u" (i32.const 11)) (i32.const 0x13))
(assert_return (invoke "i32.load8_u" (i32.const 12)) (i32.const 0x14))
(assert_return (invoke "i32.load8_u" (i32.const 13)) (i32.const 0x15))
(assert_return (invoke "i32.load8_u" (i32.const 14)) (i32.const 0x16))
(assert_return (invoke "i32.load8_u" (i32.const 15)) (i32.const 0x17))
(assert_return (invoke "i32.load8_u" (i32.const 16)) (i32.const 0x00))

(assert_return (invoke "memory.copy" (i32.const 0) (i32.const 4) (i32.const 8)))
(assert_return (invoke "i32.load8_u" (i32.const 0)) (i32.const 0x14))
(assert_return (invoke "i32.load8_u" (i32.const 1)) (i32.const 0x15))
(assert_return (invoke "i32.load8_u" (i32.const 2)) (i32.const 0x16))
(assert_return (invoke "i32.load8_u" (i32.const 3)) (i32.const 0x17))
(assert_return (invoke "i32.load8_u" (i32.const 4)) (i32.const 0x10))
(assert_return (invoke "i32.load8_u" (i32.const 5)) (i32.const 0x11))
(assert_return (invoke "i32.load8_u" (i32.const 6)) (i32.const 0x12))
(assert_return (invoke "i32.load8_u" (i32.const 7)) (i32.const 0x13))
(assert_return (invoke "i32.load8_u" (i32.const 8)) (i32.const 0x10))

(assert_return (invoke "memory.copy" (i32.const 15) (i32.const 0) (i32.const 7)))
(assert_return (invoke "i32.load8_u" (i32.const 14)) (i32.const 0x16))
(assert_return (invoke "i32.load8_u" (i32.const 15)) (i32.const 0x14))
(assert_return (invoke "i32.load8_u" (i32.const 16)) (i32.const 0x15))
(assert_return (invoke "i32.load8_u" (i32.const 17)) (i32.const 0x16))
(assert_return (invoke "i32.load8_u" (i32.const 18)) (i32.const 0x17))
(assert_return (invoke "i32.load8_u" (i32.const 19)) (i32.const 0x10))
(assert_return (invoke "i32.load8_u" (i32.const 20)) (i32.const 0x11))
(assert_return (invoke "i32.load8_u" (i32.const 21)) (i32.const 0x12))
(assert_return (invoke "i32.load8_u" (i32.const 22)) (i32.const 0))

(assert_return (invoke "memory.copy" (i32.const 65535) (i32.const 0)     (i32.const 1)))
(assert_trap   (invoke "memory.copy" (i32.const 65535) (i32.const 0)     (i32.const 2)) "out of bounds memory access")
(assert_trap   (invoke "memory.copy" (i32.const 65536) (i32.const 0)     (i32.const 1)) "out of bounds memory access")
(assert_return (invoke "memory.copy" (i32.const 100)   (i32.const 65535) (i32.const 1)))
(assert_trap   (invoke "memory.copy" (i32.const 100)   (i32.const 65536) (i32.const 2)) "out of bounds memory access")
(assert_trap   (invoke "memory.copy" (i32.const 100)   (i32.const 65536) (i32.const 1)) "out of bounds memory access")

(assert_trap   (invoke "memory.copy" (i32.const 0xffffffff) (i32.const 0) (i32.const 1)) "out of bounds memory access")
(assert_trap   (invoke "memory.copy" (i32.const 0) (i32.const 0xffffffff) (i32.const 1)) "out of bounds memory access")

;; memory.fill

(module
	(memory $m 1 1)
	
	(func (export "memory.fill")
		(param $destAddress i32)
		(param $value i32)
		(param $numBytes i32)
		(memory.fill (get_local $destAddress) (get_local $value) (get_local $numBytes))
	)
	
	(func (export "i32.load8_u") (param $address i32) (result i32)
		(i32.load8_u (get_local $address))
	)
)

(assert_return (invoke "memory.fill" (i32.const 0) (i32.const 1) (i32.const 4)))
(assert_return (invoke "i32.load8_u" (i32.const 0)) (i32.const 1))
(assert_return (invoke "i32.load8_u" (i32.const 1)) (i32.const 1))
(assert_return (invoke "i32.load8_u" (i32.const 2)) (i32.const 1))
(assert_return (invoke "i32.load8_u" (i32.const 3)) (i32.const 1))
(assert_return (invoke "i32.load8_u" (i32.const 4)) (i32.const 0))

(assert_return (invoke "memory.fill" (i32.const 4) (i32.const 2) (i32.const 4)))
(assert_return (invoke "i32.load8_u" (i32.const 3)) (i32.const 1))
(assert_return (invoke "i32.load8_u" (i32.const 4)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 5)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 6)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 7)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 8)) (i32.const 0))

(assert_return (invoke "memory.fill" (i32.const 4) (i32.const 2) (i32.const 4)))
(assert_return (invoke "i32.load8_u" (i32.const 4)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 5)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 6)) (i32.const 2))
(assert_return (invoke "i32.load8_u" (i32.const 7)) (i32.const 2))

(assert_return (invoke "memory.fill" (i32.const 65535) (i32.const 0) (i32.const 1)))
(assert_trap   (invoke "memory.fill" (i32.const 65535) (i32.const 0) (i32.const 2)) "out of bounds memory access")
(assert_trap   (invoke "memory.fill" (i32.const 65536) (i32.const 0) (i32.const 1)) "out of bounds memory access")

(assert_trap   (invoke "memory.fill" (i32.const 0xffffffff) (i32.const 0) (i32.const 1)) "out of bounds memory access")

;; passive elem segments

(assert_invalid
	(module (elem passive $f) (func $f))
	"elem segment without table"
)
(assert_invalid
	(module (table $t 1) (elem passive (i32.const 0) $f) (func $f))
	"unexpected expression"
)

(module binary
	"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

	"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
	"\60\00\00"                          ;;   Function type () -> ()

	"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
	"\00"                                ;;   Function 0: type 0

	"\04\04\01"                          ;; table section: 4 bytes, 1 entry
	"\70\00\01"                          ;;   (table 1 anyfunc)
	
	"\09\07\01"                          ;; elem section: 7 bytes, 1 entry
	"\00"                                ;;   [0] active elem segment
	"\41\00\0b"                          ;;     base offset (i32.const 0)
	"\01"                                ;;     elem segment with 1 element
	"\00"                                ;;     [0] function 0
	
	"\0a\04\01"                          ;; Code section
	"\02\00"                             ;; function 0: 2 bytes, 0 local sets
	"\0b"                                ;; end
)

(module binary
	"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

	"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
	"\60\00\00"                          ;;   Function type () -> ()

	"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
	"\00"                                ;;   Function 0: type 0

	"\04\04\01"                          ;; table section: 4 bytes, 1 entry
	"\70\00\01"                          ;;   (table 1 anyfunc)
	
	"\09\04\01"                          ;; elem section: 7 bytes, 1 entry
	"\01"                                ;;   [0] passive elem segment
	"\01"                                ;;     elem segment with 1 element
	"\00"                                ;;     [0] function 0
	
	"\0a\04\01"                          ;; Code section
	"\02\00"                             ;; function 0: 2 bytes, 0 local sets
	"\0b"                                ;; end
)

(module binary
	"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

	"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
	"\60\00\00"                          ;;   Function type () -> ()

	"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
	"\00"                                ;;   Function 0: type 0

	"\04\04\01"                          ;; table section: 4 bytes, 1 entry
	"\70\00\01"                          ;;   (table 1 anyfunc)
	
	"\09\08\01"                          ;; elem section: 8 bytes, 1 entry
	"\02\00"                             ;;   [0] active elem segment, memory 0
	"\41\00\0b"                          ;;     base offset (i32.const 0)
	"\01"                                ;;     elem segment with 1 element
	"\00"                                ;;     [0] function 0
	
	"\0a\04\01"                          ;; Code section
	"\02\00"                             ;; function 0: 2 bytes, 0 local sets
	"\0b"                                ;; end
)

;; table.init and table.drop

(module binary
	"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

	"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
	"\60\00\00"                          ;;   Function type () -> ()

	"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
	"\00"                                ;;   Function 0: type 0

	"\04\04\01"                          ;; table section: 4 bytes, 1 entry
	"\70\00\01"                          ;;   (table 1 anyfunc)
	
	"\09\04\01"                          ;; elem section: 7 bytes, 1 entry
	"\01"                                ;;   [0] passive elem segment
	"\01"                                ;;     elem segment with 1 element
	"\00"                                ;;     [0] function 0
	
	"\0a\11\01"                          ;; Code section
	"\0f\00"                             ;; function 0: 15 bytes, 0 local sets
	"\41\00"                             ;; i32.const 0
	"\41\00"                             ;; i32.const 0
	"\41\00"                             ;; i32.const 0
	"\fc\0c\00\00"                       ;; table.init 0 0
	"\fc\0d\00"                          ;; table.drop 0
	"\0b"                                ;; end
)

(assert_invalid
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

		"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
		"\60\00\00"                          ;;   Function type () -> ()

		"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
		"\00"                                ;;   Function 0: type 0

		"\04\04\01"                          ;; table section: 4 bytes, 1 entry
		"\70\00\01"                          ;;   (table 1 anyfunc)
	
		"\09\07\01"                          ;; elem section: 7 bytes, 1 entry
		"\00"                                ;;   [0] active elem segment
		"\41\00\0b"                          ;;     base offset (i32.const 0)
		"\01"                                ;;     elem segment with 1 element
		"\00"                                ;;     [0] function 0
	
		"\0a\0e\01"                          ;; Code section
		"\0c\00"                             ;; function 0: 12 bytes, 0 local sets
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\fc\0c\00\00"                       ;; table.init 0 0
		"\0b"                                ;; end
	)
	"active elem segment can't be used as source for table.init"
)

(assert_invalid
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

		"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
		"\60\00\00"                          ;;   Function type () -> ()

		"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
		"\00"                                ;;   Function 0: type 0

		"\04\04\01"                          ;; table section: 4 bytes, 1 entry
		"\70\00\01"                          ;;   (table 1 anyfunc)
	
		"\09\07\01"                          ;; elem section: 7 bytes, 1 entry
		"\00"                                ;;   [0] active elem segment
		"\41\00\0b"                          ;;     base offset (i32.const 0)
		"\01"                                ;;     elem segment with 1 element
		"\00"                                ;;     [0] function 0
	
		"\0a\06\01"                          ;; Code section
		"\05\00"                             ;; function 0: 5 bytes, 0 local sets
		"\fc\0d\00"                          ;; table.drop 0
		"\0b"                                ;; end
	)
	"active elem segment can't be used as source for table.drop"
)

(module
	(table $t 8 8 anyfunc)
	
	(type $type_i32 (func (result i32)))
	(type $type_i64 (func (result i64)))

	(elem passive $0 $1)
	(elem passive $2 $3)

	(func $0 (type $type_i32) (result i32) i32.const 0)
	(func $1 (type $type_i32) (result i32) i32.const 1)
	(func $2 (type $type_i64) (result i64) i64.const 2)
	(func $3 (type $type_i64) (result i64) i64.const 3)

	(func (export "call_indirect i32") (param $index i32) (result i32)
		(call_indirect (type $type_i32) (get_local $index))
	)
	
	(func (export "call_indirect i64") (param $index i32) (result i64)
		(call_indirect (type $type_i64) (get_local $index))
	)

	(func (export "table.init 0")
		(param $destOffset i32)
		(param $sourceOffset i32)
		(param $numElements i32)
		(table.init 0 $t (get_local $destOffset) (get_local $sourceOffset) (get_local $numElements))
	)
	
	(func (export "table.init 1")
		(param $destOffset i32)
		(param $sourceOffset i32)
		(param $numElements i32)
		(table.init 1 $t (get_local $destOffset) (get_local $sourceOffset) (get_local $numElements))
	)
	
	(func (export "table.drop 0") (table.drop 0))
	(func (export "table.drop 1") (table.drop 1))
)

(assert_trap   (invoke "call_indirect i32" (i32.const 0)) "undefined table element")

(assert_return (invoke "table.init 0" (i32.const 0) (i32.const 0) (i32.const 2)))
(assert_return (invoke "call_indirect i32" (i32.const 0)) (i32.const 0))
(assert_return (invoke "call_indirect i32" (i32.const 1)) (i32.const 1))
(assert_trap   (invoke "call_indirect i32" (i32.const 2)) "undefined table element")

(assert_return (invoke "table.init 1" (i32.const 2) (i32.const 0) (i32.const 2)))
(assert_return (invoke "call_indirect i64" (i32.const 2)) (i64.const 2))
(assert_return (invoke "call_indirect i64" (i32.const 3)) (i64.const 3))
(assert_trap   (invoke "call_indirect i64" (i32.const 4)) "undefined table element")

(assert_return (invoke "table.init 0" (i32.const 4) (i32.const 0) (i32.const 1)))
(assert_return (invoke "call_indirect i32" (i32.const 4)) (i32.const 0))
(assert_trap   (invoke "call_indirect i32" (i32.const 5)) "undefined table element")

(assert_return (invoke "table.init 1" (i32.const 5) (i32.const 1) (i32.const 1)))
(assert_return (invoke "call_indirect i64" (i32.const 5)) (i64.const 3))
(assert_trap   (invoke "call_indirect i64" (i32.const 6)) "undefined table element")

(assert_trap   (invoke "table.init 0" (i32.const 8) (i32.const 0) (i32.const 1)) "out of bounds memory access")
(assert_trap   (invoke "table.init 0" (i32.const 7) (i32.const 0) (i32.const 2)) "out of bounds memory access")
(assert_trap   (invoke "table.init 0" (i32.const 6) (i32.const 1) (i32.const 2)) "out of bounds memory access")
(assert_trap   (invoke "table.init 0" (i32.const 5) (i32.const 0) (i32.const 3)) "out of bounds memory access")

(assert_trap   (invoke "table.init 0" (i32.const 0xffffffff) (i32.const 0) (i32.const 1)) "out of bounds memory access")
(assert_trap   (invoke "table.init 0" (i32.const 0) (i32.const 0xffffffff) (i32.const 1)) "out of bounds memory access")

(assert_return (invoke "table.drop 0"))
(assert_trap   (invoke "table.init 0" (i32.const 0) (i32.const 0) (i32.const 2)) "invalid argument")
(assert_trap   (invoke "table.drop 0") "invalid argument")
(assert_return (invoke "table.init 1" (i32.const 0) (i32.const 0) (i32.const 2)))
(assert_return (invoke "call_indirect i64" (i32.const 0)) (i64.const 2))
(assert_return (invoke "call_indirect i64" (i32.const 1)) (i64.const 3))

(assert_return (invoke "table.drop 1"))
(assert_trap   (invoke "table.init 1" (i32.const 0) (i32.const 0) (i32.const 2)) "invalid argument")
(assert_trap   (invoke "table.drop 1") "invalid argument")

;; table.copy

(module binary
	"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

	"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
	"\60\00\00"                          ;;   Function type () -> ()

	"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
	"\00"                                ;;   Function 0: type 0

	"\04\04\01"                          ;; table section: 4 bytes, 1 entry
	"\70\00\01"                          ;;   (table 1 anyfunc)
	
	"\09\04\01"                          ;; elem section: 7 bytes, 1 entry
	"\01"                                ;;   [0] passive elem segment
	"\01"                                ;;     elem segment with 1 element
	"\00"                                ;;     [0] function 0
	
	"\0a\0d\01"                          ;; Code section
	"\0b\00"                             ;; function 0: 11 bytes, 0 local sets
	"\41\00"                             ;; i32.const 0
	"\41\00"                             ;; i32.const 0
	"\41\00"                             ;; i32.const 0
	"\fc\0e\00"                          ;; table.copy 0
	"\0b"                                ;; end
)

(assert_invalid
	(module binary
		"\00asm" "\01\00\00\00"              ;; WebAssembly version 1

		"\01\04\01"                          ;; Type section: 4 bytes, 1 entry
		"\60\00\00"                          ;;   Function type () -> ()

		"\03\02\01"                          ;; Function section: 2 bytes, 1 entry
		"\00"                                ;;   Function 0: type 0

		"\04\04\01"                          ;; table section: 4 bytes, 1 entry
		"\70\00\01"                          ;;   (table 1 anyfunc)
	
		"\09\04\01"                          ;; elem section: 7 bytes, 1 entry
		"\01"                                ;;   [0] passive elem segment
		"\01"                                ;;     elem segment with 1 element
		"\00"                                ;;     [0] function 0
	
		"\0a\0e\01"                          ;; Code section
		"\0b\00"                             ;; function 0: 11 bytes, 0 local sets
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\41\00"                             ;; i32.const 0
		"\fc\0e\01"                          ;; table.copy 1
		"\0b"                                ;; end
	)
	"invalid table index"
)

(module
	(table $t 8 8 anyfunc)
	
	(type $type_i32 (func (result i32)))
	(type $type_i64 (func (result i64)))

	(elem $t (i32.const 0) $0 $1 $2 $3)

	(func $0 (type $type_i32) (result i32) i32.const 0)
	(func $1 (type $type_i32) (result i32) i32.const 1)
	(func $2 (type $type_i64) (result i64) i64.const 2)
	(func $3 (type $type_i64) (result i64) i64.const 3)

	(func (export "call_indirect i32") (param $index i32) (result i32)
		(call_indirect (type $type_i32) (get_local $index))
	)
	
	(func (export "call_indirect i64") (param $index i32) (result i64)
		(call_indirect (type $type_i64) (get_local $index))
	)

	(func (export "table.copy")
		(param $destOffset i32)
		(param $sourceOffset i32)
		(param $numElements i32)
		(table.copy (get_local $destOffset) (get_local $sourceOffset) (get_local $numElements))
	)
)

(assert_trap   (invoke "call_indirect i32" (i32.const 4)) "undefined table element")
(assert_return (invoke "table.copy" (i32.const 4) (i32.const 0) (i32.const 4)))
(assert_return (invoke "call_indirect i32" (i32.const 4)) (i32.const 0))
(assert_return (invoke "call_indirect i32" (i32.const 4)) (i32.const 0))
(assert_return (invoke "call_indirect i32" (i32.const 5)) (i32.const 1))
(assert_return (invoke "call_indirect i64" (i32.const 6)) (i64.const 2))
(assert_return (invoke "call_indirect i64" (i32.const 7)) (i64.const 3))

(assert_return (invoke "table.copy" (i32.const 3) (i32.const 2) (i32.const 2)))
(assert_return (invoke "call_indirect i64" (i32.const 3)) (i64.const 2))
(assert_return (invoke "call_indirect i64" (i32.const 4)) (i64.const 3))

(assert_trap   (invoke "table.copy" (i32.const 8) (i32.const 0) (i32.const 1)) "out of bounds memory access")
(assert_trap   (invoke "table.copy" (i32.const 7) (i32.const 0) (i32.const 2)) "out of bounds memory access")
(assert_trap   (invoke "table.copy" (i32.const 0) (i32.const 8) (i32.const 1)) "out of bounds memory access")
(assert_trap   (invoke "table.copy" (i32.const 0) (i32.const 7) (i32.const 2)) "out of bounds memory access")

(assert_trap   (invoke "table.copy" (i32.const 0xffffffff) (i32.const 0) (i32.const 1)) "out of bounds memory access")
(assert_trap   (invoke "table.copy" (i32.const 0) (i32.const 0xffffffff) (i32.const 1)) "out of bounds memory access")
