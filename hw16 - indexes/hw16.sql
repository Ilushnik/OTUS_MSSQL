-- для быстрого поиска клиента по номеру телефона

create unique index Client_PhoneNumber_uindex
    on dbo.Client (PhoneNumber)


-- для быстрого подсчета выручки за период
create index Transaction_Date_Price_index
    on dbo.[Transaction] (Date, Price)