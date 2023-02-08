
kind:
	./scripts/kind.sh

unkind:
	kind delete cluster -nkind
e2e:
	./scripts/e2e.sh
