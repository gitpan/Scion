/*
	$ g++ -o cplusplus cplusplus.cpp

*/

#include <iostream>

class A{
	public:

	A(){
		std::cout << "A construction" << std::endl;
	}

	virtual ~A(){
		std::cout << "A destruction" << std::endl;
	}
};

class B : virtual public A{
	public:

	B(){
		std::cout << "B construction" << std::endl;
	}

	virtual ~B(){
		std::cout << "B destruction" << std::endl;
	}
};

class C : virtual public A{
	public:

	C(){
		std::cout << "C construction" << std::endl;
	}

	virtual ~C(){
		std::cout << "C destruction" << std::endl;
	}

};
class D : virtual public B, C{
	public:

	D(){
		std::cout << "D construction" << std::endl;
	}

	virtual ~D(){
		std::cout << "D destruction" << std::endl;
	}

};



int main(){
	D x;

	return 0;
}
