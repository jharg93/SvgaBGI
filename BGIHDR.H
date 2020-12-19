#ifndef __BGIHDR_H__
#define __BGIHDR_H__

#define HEADER_SIZE 0xA0

#define subRev2 1
#define subRev3 1

typedef unsigned char byte;

//=================================
class bgiHeader
{
    char myName[16];
    unsigned int  codeSize;
    unsigned char version;
    unsigned char revision;
    unsigned char subRev;
    unsigned char minVersion;
    unsigned char minRevision;
    unsigned char driverNum;
protected:
public:
    bgiHeader(char *drvName,int codeSz,int ver,int rev,int sRev,int minVer,
	      int minRev);
    virtual void writeHeader(FILE *outFile);
    void writeDriverName(FILE *outFile);
    virtual const char *header() = 0;
    virtual int isHeaderValid(const byte *) = 0;
};

//=================================
class bgiHeader2 : public bgiHeader {
public:
    bgiHeader2(char *drvName,int codeSz);
    void writeHeader(FILE *outFile)  { bgiHeader::writeHeader(outFile); };
    const char *header() { return ("pk\x8\x8"); };
    virtual int isHeaderValid(const byte *);
};

//=================================
class bgiHeader3 : public bgiHeader {
    unsigned int  dataOfs;
    unsigned int  dataSize;
public:
    bgiHeader3(char *drvName,unsigned int codeSz,unsigned int dataOffset,unsigned int dataSz);
    void writeHeader(FILE *outFile);
    const char *header() { return ("FBGD\x8\x8\x8\x8"); };
    virtual int isHeaderValid(const byte *);
};

#endif /* __BGIHDR_H__ */
