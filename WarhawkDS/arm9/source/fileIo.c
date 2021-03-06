#include <nds.h>
#include <stdio.h>
#include <malloc.h>
#include <fat.h>
#include <unistd.h>


#include "efs_lib.h"    // include EFS lib

char *pFileBuffer = NULL;
FILE *pFileStream = NULL;

int readFile(char *fileName)
{ 
	FILE *pFile;
	struct stat fileStat;
	size_t result;
	
	if(pFileBuffer != NULL)
		free(pFileBuffer);

	pFile = fopen(fileName, "rb");
	
	if(pFile == NULL)
		return 0;

	if(stat(fileName, &fileStat) != 0)
	{
		fclose(pFile);
		return 0;
	}

	pFileBuffer = (char *) malloc(fileStat.st_size);
	
	if(pFileBuffer == NULL)
	{
		fclose(pFile);
		return 0;
	}
	
	result = fread(pFileBuffer, 1, fileStat.st_size, pFile);
	
	if(result != fileStat.st_size)
	{
		fclose(pFile);
		return 0;
	}

	fclose(pFile);
	
	return result;
}

int readFileBuffer(char *fileName, char *pBuffer)
{ 
	FILE *pFile;
	struct stat fileStat;
	size_t result;

	pFile = fopen(fileName, "rb");
	
	if(pFile == NULL)
		return 0;

	if(stat(fileName, &fileStat) != 0)
	{
		fclose(pFile);
		return 0;
	}

	result = fread(pBuffer, 1, fileStat.st_size, pFile);
	
	if(result != fileStat.st_size)
	{
		fclose(pFile);
		return 0;
	}

	fclose(pFile);
	
	return result;
}

int writeFileBuffer(char *fileName, char *pBuffer)
{ 
	FILE *pFile;
	struct stat fileStat;
	size_t result;

	pFile = fopen(fileName, "wb+");
	
	if(pFile == NULL)
		return 0;
		
	if(stat(fileName, &fileStat) != 0)
	{
		fclose(pFile);
		return 0;
	}

	result = fwrite(pBuffer, 1, fileStat.st_size, pFile);
	
	if(result != fileStat.st_size)
	{
		fclose(pFile);
		return 0;
	}

	fclose(pFile);
	
	return result;
}

/* int writeFileBuffer(char *fileName, char *pBuffer, int size)
{ 
	FILE *pFile;
	size_t result;

	pFile = fopen(fileName, "wb+");
	
	if(pFile == NULL)
		return 0;
		
	result = fwrite(pBuffer, 1, size, pFile);
	
	if(result != size)
	{
		fclose(pFile);
		return 0;
	}

	fclose(pFile);
	
	return result;
} */

int initFileStream(char *fileName)
{
	struct stat fileStat;
	
	if(pFileStream != NULL)
		fclose(pFileStream);
	
	pFileStream = fopen(fileName, "rb");
	
	if(pFileStream == NULL)
		return 0;

	if(stat(fileName, &fileStat) != 0)
		return 0;

	return fileStat.st_size;
}

int readFileStream(char *pBuffer, int size)
{ 
	int result;
	
	if(pFileStream == NULL)
		return 0;
	
	result = fread(pBuffer, 1, size, pFileStream);
	
	return result;
}

int resetFileStream()
{ 
	size_t result;
	
	if(pFileStream == NULL)
		return 0;
	
	result = fseek(pFileStream, 0, SEEK_SET);
	
	if(result != 0)
		return 0;
	
	return 1;
}

int closeFileStream()
{ 
	if(pFileStream != NULL)
	{
		fclose(pFileStream);
		
		return 1;
	}
	
	return 0;
}

int readFileSize(char *fileName)
{
	struct stat fileStat;
	size_t result;
	
	result = stat(fileName, &fileStat);
	
	if(result != 0)
		return 0;
		
	return fileStat.st_size;
}
