import { LightningElement, wire, track } from 'lwc';
import { subscribe, unsubscribe, MessageContext } from 'lightning/messageService';
import getOrdersForCurrentUser from '@salesforce/apex/OrderController.getOrdersForCurrentUser';
import getOrderItems from '@salesforce/apex/OrderController.getOrderItems';
import getCurrentUser from '@salesforce/apex/OrderController.getCurrentUser';


export default class OrderList extends LightningElement {
    @track orders = [];
    @track error;
    @track isModalOpen = false;
    @track selectedOrderId;

    @track orderItems = [];
    @track orderItemsError;
    @track isLoadingItems = false;
    user;
    conversationId;
    queuedMessage;
    subscription = null;

    @wire(getOrdersForCurrentUser)
    wiredOrders({ data, error }) {
        if (data) {
            this.orders = data.map(o => {
                const accountName = o.Account ? o.Account.Name : '';
                const totalNumber = o.TotalAmount != null ? Number(o.TotalAmount) : 0;
                return {
                    ...o,
                    AccountName: accountName,
                    EffectiveDate: o.EffectiveDate ? new Date(o.EffectiveDate).toLocaleDateString() : '',
                    TotalAmount: '$' + totalNumber.toLocaleString(),
                    statusClass: this.getStatusClass(o.Status)
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.orders = undefined;
        }
    }
    connectedCallback() {
        this.fetchCurrentUser();
        window.addEventListener("onEmbeddedMessageSent", this.handleEmbeddedMessage);
    }

    disconnectedCallback() {
        this.unsubscribeFromPreChatMessage();
        window.removeEventListener("onEmbeddedMessageSent", this.handleEmbeddedMessage);
    }

    handleEmbeddedMessage(event) {
        console.log('Embedded Message Event:', event);
    }

    fetchCurrentUser() {
        getCurrentUser()
            .then(result => {
                this.user = result;
                console.log('User Info:', JSON.stringify(this.user));

                window.dispatchEvent(new CustomEvent('userInfo', {
                    detail: { endUserId: 'aman.thakur@lirik.io' }
                }));
            })
            .catch(error => {
                console.error('Error fetching user details:', error);
            });
    }



    getStatusClass(status) {
        switch (status) {
            case 'Draft': return 'badge-grey';
            case 'Delivered': return 'badge-green';
            case 'In Transit': return 'badge-yellow';
            case 'Delayed': return 'badge-red';
            default: return '';
        }
    }

    get hasOrderItems() {
        return this.orderItems && this.orderItems.length > 0;
    }

    handleViewDetails(event) {
        this.selectedOrderId = event.target.dataset.id;
        this.isModalOpen = true;

        this.isLoadingItems = true;
        getOrderItems({ orderId: this.selectedOrderId })
            .then(data => {
                this.orderItemsError = undefined;
                const safeData = Array.isArray(data) ? data : [];
                this.orderItems = safeData.map(item => {
                    const pbe = item.PricebookEntry;
                    const prod = pbe && pbe.Product2 ? pbe.Product2 : null;
                    const unit = item.UnitPrice != null ? Number(item.UnitPrice) : 0;
                    const total = item.TotalPrice != null ? Number(item.TotalPrice) : 0;
                    return {
                        Id: item.Id,
                        ProductName: prod ? prod.Name : '',
                        Family: prod ? (prod.Family || '') : '',
                        Quantity: item.Quantity,
                        UnitPrice: unit,
                        TotalPrice: total,
                        UnitPriceDisplay: this.formatCurrency(unit),
                        TotalPriceDisplay: this.formatCurrency(total)
                    };
                });
            })
            .catch(error => {
                this.orderItems = [];
                this.orderItemsError = error;
            })
            .finally(() => {
                this.isLoadingItems = false;
            });
    }

    closeModal() {
        this.isModalOpen = false;
        this.selectedOrderId = null;
        this.orderItems = [];
        this.orderItemsError = undefined;
        this.isLoadingItems = false;
    }

    formatCurrency(amount) {
        // Adjust currency if needed (defaults to USD)
        try {
            return (Number(amount) || 0).toLocaleString(undefined, { style: 'currency', currency: 'USD' });
        } catch (e) {
            return '$' + (Number(amount) || 0).toLocaleString();
        }
    }
}