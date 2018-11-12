#Project 1 R program to crawl, parse and extract all articles published in a specific journal
#Group 1: Aakash Asli, Shao Yu Chen, Tushar Asnani
#2018 Fall

#Journal Name: Genome Biology
#Main page of the journal: https://genomebiology.biomedcentral.com/

source(paste(getwd(),"/util.R",sep=""))
library(bitops)
library(RCurl)
library(XML)
library(stringr)
library(httr)

#load(readLines) main page & save to (.html) file
site.url = "https://genomebiology.biomedcentral.com"
site.url.clear = "https://genomebiology.biomedcentral.com"
main.page = readLines(site.url)
options(warn=-1)
dir.create("HTMLs")
write(main.page, file = "HTMLs/main_page.html")
print("[I/O]: FILE: main_page.html created.")

#get the link of "Article List Page" URL from main page
page.list.url = paste(site.url,substr(main.page[grep("(<a class=.c-navbar__link.+ href).+(>Articles<\\/a>)",main.page)],82,89),sep="/")
#page.list.url = paste(site.url,"Articles",sep="")
page.list = readLines(page.list.url)
write(page.list, file="HTMLs/Article_List_Page1.html")
print("[I/O]: FILE: article_list_page.html created.")

#get the URL of all "Article list page" url, total 126 pages, each page has maximum 50 articles
#find max page numbers
page_index = str_extract_all(page.list[grep('<p class=\\"u-text-neutral-50 u-text-sm u-reset-margin\\">Page \\d+ of \\d+<\\/p>',page.list)][1],"\\d+")[[1]];
min.page.count = page_index[2];
max.page.count = page_index[3];
#page.url = paste(site.url, str_extract(page.list[grep('<a class="Pager Pager--next".+',page.list)][1],"articles\\?.+page\\="),sep="")
page.url = paste(site.url, str_extract(page.list[tail(grep('<li class="c-pagination__item">',page.list),n=1)+2][1],"articles\\?.+page\\="),sep="/")
page.url = xpathApply(htmlParse(page.url, asText=TRUE),"//body//text()", xmlValue)[[1]]

#generate article url list
page.url.list = ""
article.data = data.frame(DOI=c(),url=c())
for(i in min.page.count:max.page.count){
  percent = toString(as.integer((i/as.integer(max.page.count))*100))
  cat("\r",paste("[APP]: loading page number: ",i," [", percent, "%]"))
  full.url = paste(page.url,i,sep="")
  articleUrl_and_doi = loadArticleList(full.url)#function call: loadArticleList()
  articleUrl_and_doi$url = paste(site.url.clear, articleUrl_and_doi$url, sep="")#add site url, to fulfill the url of an article
  article.data = rbind(article.data, articleUrl_and_doi)#rown bind, store all article DOI, urls
  page.url.list = c(page.url.list, full.url)
}
page.url.list = page.url.list[-1]
write(page.url.list, "page.url.list.txt")
print("[I/O]: FILE: page.url.list.txt created.")
write.csv(article.data, "article.DOI.URL.list.csv")
print("[I/O]: FILE: article.DOI.URL.list.csv created.")


#circuly analysis the articles and extract required information, and form all information in a data.frame
extracted.data = data.frame(DOI=c(),Title=c(),Author=c(), "Author Affiliation"=c(), "Corresponding Author"=c(), "Corresponding_Author_email"=c(), 
                            "Publication Date"=c(), Abstract=c(), Keywords=c(), "Full Text"=c())
total.number = as.integer(length(article.data[,1]))
for(i in 1:total.number){
  #print(paste("Use this--->",article.data[i,2]))
  extracted.data = rbind(extracted.data, analysisArticle(article.data[i,1], article.data[i,2]))#function call: analysisArticle
  cat("\r", paste("[I/O]: FILE:", toString(i), article.data[i,1], ".html created. [",toString(as.integer(i/total.number*100)), "%]"))
}


#Write the final result to Genome Biology.txt
options(warn=-1)
dir.create("output")
write.table(extracted.data,"output/Genome Biology.txt",sep="\t",row.names=FALSE,fileEncoding = "UTF-8")
print("[I/O]: FILE: output/Genome Biology.txt created.")